# backend_image = "070008302895.dkr.ecr.eu-central-1.amazonaws.com/bet2wealth-backend-production:latest"
# Always pass the backend image to the terraform apply or plan command. 
# terraform plan -var="backend_image=070008302895.dkr.ecr.eu-central-1.amazonaws.com/bet2wealth-backend-production:<sha>"
# terraform apply -var="backend_image=070008302895.dkr.ecr.eu-central-1.amazonaws.com/bet2wealth-backend-production:<sha>"
# sha is the image sha1 hash of the backend image in ECR after docker build.

domain_name = "api.bet2wealth.co"

health_check_path = "/api/v1/health-check"

# GitHub Actions OIDC + deploy role (production)
create_github_oidc_provider               = false
create_github_actions_deploy_role         = true
github_repo                               = "UtivaHQ/bet2wealth_backend"
github_branches                           = ["main"]
github_actions_deploy_attach_admin_policy = true

# Container environment variables
# Non-secret env vars only
container_environment = {
  NODE_ENV   = "production"
  BRANCH_ENV = "main"
  PORT       = "4000"

  APP_NAME    = "Bet2wealth"
  APP_VERSION = "0.0.1"

  SENTRY_ENV = "production"

  HOST_URL   = "https://api.bet2wealth.co"
  ROOT_ENTRY = "/api/v1"
  API_DOCS   = "/api/v1/docs"

  JWT_EXPIRY         = "1h"
  JWT_REFRESH_EXPIRY = "7d"

  MONGOOSE_DEBUG = false

  REDIS_URL                  = "redis://master.bet2wealth-redis-cluster-production.naxfsj.euc1.cache.amazonaws.com:6379"
  REDIS_POOL_MAX             = 50
  REDIS_POOL_MIN             = 5
  REDIS_POOL_IDLE_TIMEOUT    = 300000
  REDIS_POOL_ACQUIRE_TIMEOUT = 10000
  REDIS_POOL_RETRY_ATTEMPTS  = 3

  # SMTP
  SMTP_HOST   = "email-smtp.eu-central-1.amazonaws.com"
  SMTP_PORT   = 465
  SMTP_SECURE = false
  MAIL_FROM   = "no-reply@dev.bet2wealth.co"

  # Server config
  GENERAL_SERVER_TASK_DURATION = 30
  RATE_LIMIT_DURATION_SECONDS  = 60
  RATE_LIMIT_PERMISSION_POINTS = 100

  # Bitville integration
  BITVILLE_ACCOUNT    = "dev-bet2wealth-nig"
  BITVILLE_SERVER_URL = "https://dev-games.bitville-api.com"

  # Termii SMS service
  TERMII_SENDER_ID            = "Bet2wealth"
  TERMII_CHANNEL              = "generic"
  TERMII_BASE_URL             = "https://v3.api.termii.com"
  TERMII_DEFAULT_COUNTRY_CODE = "234"

  # Paystack payments
  PAYSTACK_PUBLIC_KEY = "pk_test_a8f597d23f1a21f20b09ce328c69f29f95b661fb"
  PAYSTACK_BASE_URL   = "https://api.paystack.co"

  # Fundist Integration
  FUNDIST_API_URL           = "https://apitest.fundist.org/"
  FUNDIST_CALLBACK_BASE_URL = "https://api.bet2wealth.co"
}

# Secret environment variables
container_secrets = {
  SENTRY_DSN = "arn:aws:ssm:eu-central-1:070008302895:parameter/bet2wealth/production/SENTRY_DSN"

  JWT_SECRET         = "arn:aws:ssm:eu-central-1:070008302895:parameter/bet2wealth/production/JWT_SECRET"
  JWT_REFRESH_SECRET = "arn:aws:ssm:eu-central-1:070008302895:parameter/bet2wealth/production/JWT_REFRESH_SECRET"

  MONGO_HOST        = "arn:aws:ssm:eu-central-1:070008302895:parameter/bet2wealth/production/MONGO_HOST"
  MONGO_SECURE_HOST = "arn:aws:ssm:eu-central-1:070008302895:parameter/bet2wealth/production/MONGO_SECURE_HOST"
  MONGO_HOST_TEST   = "arn:aws:ssm:eu-central-1:070008302895:parameter/bet2wealth/production/MONGO_HOST_TEST"

  SMTP_USER     = "arn:aws:ssm:eu-central-1:070008302895:parameter/bet2wealth/production/SMTP_USER"
  SMTP_PASSWORD = "arn:aws:ssm:eu-central-1:070008302895:parameter/bet2wealth/production/SMTP_PASSWORD"

  BITVILLE_PRIVATE_KEY = "arn:aws:ssm:eu-central-1:070008302895:parameter/bet2wealth/production/BITVILLE_PRIVATE_KEY"

  TERMII_API_KEY = "arn:aws:ssm:eu-central-1:070008302895:parameter/bet2wealth/production/TERMII_API_KEY"

  PAYSTACK_SECRET_KEY = "arn:aws:ssm:eu-central-1:070008302895:parameter/bet2wealth/production/PAYSTACK_SECRET_KEY"

  GOOGLE_OAUTH_CLIENT_SECRET = "arn:aws:ssm:eu-central-1:070008302895:parameter/bet2wealth/production/GOOGLE_OAUTH_CLIENT_SECRET"
  GOOGLE_OAUTH_CLIENT_ID     = "arn:aws:ssm:eu-central-1:070008302895:parameter/bet2wealth/production/GOOGLE_OAUTH_CLIENT_ID"

  MAILERSEND_API_KEY = "arn:aws:ssm:eu-central-1:070008302895:parameter/bet2wealth/production/MAILERSEND_API_KEY"

  FUNDIST_API_KEY      = "arn:aws:ssm:eu-central-1:070008302895:parameter/bet2wealth/dev/FUNDIST_API_KEY"
  FUNDIST_API_PASSWORD = "arn:aws:ssm:eu-central-1:070008302895:parameter/bet2wealth/dev/FUNDIST_API_PASSWORD"
  FUNDIST_HMAC_SECRET  = "arn:aws:ssm:eu-central-1:070008302895:parameter/bet2wealth/dev/FUNDIST_HMAC_SECRET"
  FUNDIST_SYSTEM_ID    = "arn:aws:ssm:eu-central-1:070008302895:parameter/bet2wealth/dev/FUNDIST_SYSTEM_ID"
}
