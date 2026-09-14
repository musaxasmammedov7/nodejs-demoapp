# Terragrunt — Полный конспект

## 1. Что такое Terragrunt

Terragrunt — это **обёртка над Terraform**, которая решает проблему дублирования кода при работе с несколькими окружениями.

### Зачем нужен

Без Terragrunt (чистый Terraform):
```hcl
# dev/main.tf
terraform {
  backend "s3" {
    bucket = "my-state"
    key    = "dev/terraform.tfstate"
  }
}
provider "aws" { region = "us-east-1" }
module "vpc" { source = "./modules/vpc" }

# production/main.tf — ТОТ ЖЕ КОД, просто другой key
terraform {
  backend "s3" {
    bucket = "my-state"
    key    = "production/terraform.tfstate"
  }
}
provider "aws" { region = "us-east-1" }
module "vpc" { source = "./modules/vpc" }
```

Дублирование: provider, backend, source модулей. При 5 окружениях — 5 копий.

С Terragrunt:
```hcl
# terragrunt.hcl (ОДИН раз)
generate "provider" { contents = "provider \"aws\" { region = var.aws_region }" }
remote_state { config = { key = "${path_relative_to_include()}/terraform.tfstate" } }

# dev/vpc/terragrunt.hcl (3 строки)
terraform { source = "../../modules//vpc" }
inputs = { environment = "dev", vpc_cidr = "10.0.0.0/16" }
```

---

## 2. Структура проекта

```
terragrunt/
├── terragrunt.hcl              # КОРНЕВОЙ конфиг (общий для всех)
│
├── modules/                    # Terraform модули (пишем ОДИН раз)
│   ├── vpc/main.tf
│   ├── sg/main.tf
│   ├── alb/main.tf
│   ├── ec2/main.tf
│   └── cloudwatch/main.tf
│
├── env/                        # TFVARS для Infracost
│   ├── dev.tfvars
│   ├── production.tfvars
│   └── load-testing.tfvars
│
├── dev/
│   ├── env.hcl                 # Переменные dev окружения
│   ├── vpc/terragrunt.hcl
│   └── app/
│       ├── sg/terragrunt.hcl
│       ├── alb/terragrunt.hcl
│       ├── ec2/terragrunt.hcl
│       └── cloudwatch/terragrunt.hcl
│
├── production/
│   ├── env.hcl
│   └── ... (аналогично dev)
│
└── load-testing/
    ├── env.hcl
    └── ... (аналогично dev)
```

---

## 3. Корневой `terragrunt.hcl`

Файл в корне `terragrunt/`. Наследуется **всеми** модулями.

### Provider (генерация)

```hcl
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
EOF
}
```

**Что делает:** Для КАЖДОГО модуля автоматически создаётся `provider.tf`. Не нужно писать в каждом файле.

### Backend (генерация)

```hcl
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = "my-state-bucket"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terragrunt-locks"
  }
}
```

**`path_relative_to_include()`** — ключевая функция. Возвращает путь от корня terragrunt до текущего модуля:

| Место запуска | Результат |
|---|---|
| `dev/vpc/terragrunt.hcl` | `dev/vpc` |
| `dev/app/ec2/terragrunt.hcl` | `dev/app/ec2` |
| `production/vpc/terragrunt.hcl` | `production/vpc` |

Итого в S3:
```
s3://my-state-bucket/
├── dev/vpc/terraform.tfstate
├── dev/app/sg/terraform.tfstate
├── dev/app/alb/terraform.tfstate
├── production/vpc/terraform.tfstate
└── ...
```

**Один бакет, но отдельный state для каждого модуля каждого окружения.**

---

## 4. `env.hcl` — переменные окружения

Каждое окружение имеет свой файл с переменными:

```hcl
# dev/env.hcl
locals {
  aws_region    = "us-east-1"
  environment   = "dev"
  vpc_cidr      = "10.0.0.0/16"
  instance_type = "t3.micro"
  min_size      = 1
  max_size      = 3
}

# production/env.hcl
locals {
  aws_region    = "us-east-1"
  environment   = "production"
  vpc_cidr      = "10.10.0.0/16"
  instance_type = "t3.small"
  min_size      = 2
  max_size      = 6
}
```

---

## 5. Чтение переменных в модулях

```hcl
locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  environment = local.env_vars.locals.environment
}
```

**`find_in_parent_folders("env.hcl")`** — ищет файл `env.hcl` поднимаясь вверх:

```
dev/app/sg/terragrunt.hcl
  → dev/app/sg/env.hcl     ✗ не нашёл
  → dev/app/env.hcl        ✗ не нашёл
  → dev/env.hcl            ✓ НАШЁЛ!
```

**`read_terragrunt_config(...)`** — читает файл и возвращает содержимое.

**`local.env_vars.locals.environment`** — берёт конкретную переменную.

---

## 6. Модули — `terraform.source`

```hcl
terraform {
  source = "../../modules//vpc"
}
```

**Двойной слэш `//`** — синтаксис Terragrunt:
- До `//` = путь к модулю (`../../modules/vpc`)
- После `//` = подпапка внутри (не используется, но нужен для Terragrunt)

**Относительные пути:**

| Файл | Путь | Куда ведёт |
|---|---|---|
| `dev/vpc/terragrunt.hcl` | `../../modules//vpc` | `terragrunt/modules/vpc` |
| `dev/app/sg/terragrunt.hcl` | `../../../modules//sg` | `terragrunt/modules/sg` |
| `dev/app/alb/terragrunt.hcl` | `../../../modules//alb` | `terragrunt/modules/alb` |

**Правило:** Считай `..` от текущей папки до корня terragrunt, потом добавь `modules/xxx`.

---

## 7. `dependency` — управление порядком

```hcl
dependency "vpc" {
  config_path = "../../vpc"
}
```

**`dependency "vpc"`** — объявляет зависимость. Имя `vpc` потом используется как `dependency.vpc.outputs.xxx`.

**`config_path`** — относительный путь к папке с `terragrunt.hcl` зависимого модуля.

### Как Terragrunt определяет порядок

1. Читает все `terragrunt.hcl` файлы
2. Анализирует все `dependency` блоки
3. Строит **граф зависимостей** (Directed Acyclic Graph — DAG)
4. Делает **topological sort** (сортировку)
5. Запускает модули в правильном порядке

### Пример графа

```
vpc (нет зависимостей)
  ↓
sg (зависит от vpc)
  ↓
alb (зависит от vpc, sg)
  ↓
ec2 (зависит от vpc, sg, alb)
  ↓
cloudwatch (зависит от ec2, alb)
```

Порядок: `vpc → sg → alb → ec2 → cloudwatch`

### Параллельный запуск

Если модули не зависят друг от друга — они запускаются **одновременно**:

```
VPC    ─────┐
            ├──→ ALB ──→ EC2
SG     ─────┘
```

### Получение outputs

```hcl
inputs = {
  vpc_id = dependency.vpc.outputs.vpc_id
}
```

Terragrunt автоматически делает `terraform output` в зависимом модуле и подставляет значение.

### Ошибки

**Циклическая зависимость:**
```
Error: Circular dependency detected: A -> B -> A
```

**Несуществующий путь:**
```
Error: path "/Users/.../vpc/terragrunt.hcl" does not exist
```

---

## 8. `inputs` — передача переменных

```hcl
inputs = {
  aws_region  = local.env_vars.locals.aws_region
  environment = local.env_vars.locals.environment
  vpc_id      = dependency.vpc.outputs.vpc_id
}
```

**`inputs`** — переменные которые передаются в Terraform модуль как `terraform.tfvars`.

Источники значений:
| Переменная | Откуда |
|---|---|
| `local.env_vars.locals.xxx` | Из `env.hcl` |
| `dependency.xxx.outputs.yyy` | Из другого модуля |
| Фиксированное значение | Константа в файле |

---

## 9. Запуск

### Одиночный модуль

```bash
cd terragrunt/dev/vpc
terragrunt apply
```

### Все модули окружения

```bash
cd terragrunt/dev
terragrunt run-all apply
```

Terragrunt автоматически определит порядок через dependency блоки.

### Конкретный модуль с планом

```bash
cd terragrunt/dev/app/ec2
terragrunt plan
```

---

## 10. State изоляция

| Подход | State файлы |
|---|---|
| Terraform | Один на все ресурсы окружения |
| **Terragrunt** | **Отдельный на каждый модуль** |

```
s3://my-state-bucket/
├── dev/vpc/terraform.tfstate           ← только VPC
├── dev/app/sg/terraform.tfstate        ← только Security Groups
├── dev/app/alb/terraform.tfstate       ← только ALB
├── dev/app/ec2/terraform.tfstate       ← только EC2
├── dev/app/cloudwatch/terraform.tfstate ← только CloudWatch
├── production/vpc/terraform.tfstate
└── ...
```

**Почему это важно:** Если сломается ALB в dev — ты пересоздаёшь ТОЛЬКО ALB. VPC, SG, EC2 не затрагиваются.

---

## 11. Альтернативы Terragrunt

### 1. Чистый Terraform

```hcl
module "vpc" {
  source = "./modules/vpc"
  environment = "dev"
}
```

- Плюсы: Просто, ничего лишнего
- Минусы: Дублирование, один state, ручной порядок
- Когда: 1-2 окружения

### 2. Симлинки

```bash
ln -sf ../common/ec2.tf .
```

- Плюсы: Нулевое дублирование
- Минусы: Один state, ручной порядок, хрупко
- Когда: 2 окружения с одинаковой логикой

### 3. Terraform Workspaces

```bash
terraform workspace new dev
terraform workspace select dev
terraform apply
```

- Плюсы: Встроено в Terraform
- Минусы: Слабая изоляция, путаница
- Когда: Быстрый прототип

### 4. `for_each` модули

```hcl
module "vpc" {
  for_each = toset(["dev", "production"])
  source   = "./modules/vpc"
  environment = each.key
}
```

- Плюсы: Всё в одном файле
- Минусы: Один state на все окружения
- Когда: Одинаковые окружения без отличий

### 5. CI/CD платформы (Atlantis, Spacelift, env0)

- Плюсы: Аудит, контроль доступа
- Минусы: Платные, сложная настройка
- Когда: Большая команда, compliance

---

## 12. Сравнительная таблица

| Подход | Изоляция state | Автопорядок | Сложность | Когда |
|---|---|---|---|---|
| Чистый Terraform | Нет | Нет | Просто | 1-2 окружения |
| Симлинки | Нет | Нет | Просто | 2 окружения |
| Workspaces | Частичная | Нет | Средне | Прототип |
| `for_each` | Нет | Нет | Средне | Одинаковые окружения |
| **Terragrunt** | **Да** | **Да** | **Средне** | **3+ окружения** |
| CI/CD платформы | Да | Да | Сложно | Команда |

---

## 13. Интеграция с Infracost

### Конфигурация `infracost.yml`

```yaml
version: "0.1"
projects:
  - path: dev/vpc
    name: dev-vpc
  - path: production/app/ec2
    name: production-ec2
```

### Запуск

```bash
# Авторизация
infracost auth login

# Оценка стоимости
infracost breakdown --config infracost.yml
```

### Результат

```
Project           Resources  Monthly Cost
dev-vpc                  14           $33
production-vpc           14           $33
production-ec2            6           $46
load-testing-ec2          6           $91
```

---

## 14. Ключевые концепции

| Концепция | Описание |
|---|---|
| `generate` | Автоматическая генерация .tf файлов |
| `remote_state` | Настройка бэкенда для state |
| `find_in_parent_folders` | Поиск файла в родительских папках |
| `read_terragrunt_config` | Чтение Terragrunt конфига |
| `path_relative_to_include` | Путь от корня до текущего модуля |
| `dependency` | Объявление зависимости от другого модуля |
| `inputs` | Переменные для Terraform модуля |
| `terraform.source` | Путь к Terraform модулю |
| DRY | Don't Repeat Yourself — не дублируй код |

---

## 15. Чеклист по настройке

1. Установить Terragrunt: `brew install terragrunt`
2. Создать корневой `terragrunt.hcl` с provider и backend
3. Создать `env.hcl` для каждого окружения
4. Создать Terraform модули в `modules/`
5. Создать `terragrunt.hcl` для каждого модуля в окружении
6. Указать `dependency` блоки для порядка запуска
7. Указать `terraform.source` с правильными путями
8. Указать `inputs` с переменными из `env.hcl` и `dependency.outputs`
9. Запустить: `terragrunt run-all apply`
