// variable "CI_REGISTRY_IMAGE" {}

// variable "CI_COMMIT_SHA" {}

// variable "CI_COMMIT_TIMESTAMP" {}

// variable "CI_PROJECT_URL" {}

// variable "CI_PROJECT_TITLE" {}

// group "gitlab" {
//     targets = [
//         "sampleapp-gitlab"
//     ]
// }

// group "github" {
//     targets = [
//         "sampleapp-github"
//     ]
// }

// target "sampleapp-gitlab" {
//   pull       = true
//   context    = "."
//   dockerfile = "Dockerfile"
//   tags       = ["${CI_REGISTRY_IMAGE}/sample-app:${CI_COMMIT_SHA}"]
//   cache-from = ["type=registry,ref=${CI_REGISTRY_IMAGE}/sample-app:cache"]
//   cache-to   = ["type=registry,ref=${CI_REGISTRY_IMAGE}/sample-app:cache,mode=max"]
//   platforms  = ["linux/amd64"]
//   labels     = {
//     "org.opencontainers.image.title": "${CI_PROJECT_TITLE}",
//     "org.opencontainers.image.description": "${CI_PROJECT_TITLE}",
//     "org.opencontainers.image.url": "${CI_PROJECT_URL}",
//     "org.opencontainers.image.source": "${CI_PROJECT_URL}",
//     "org.opencontainers.image.version": "${CI_COMMIT_SHA}",
//     "org.opencontainers.image.created": "${CI_COMMIT_TIMESTAMP}",
//     "org.opencontainers.image.revision": "${CI_COMMIT_SHA}",
//   }
// }


variable "GITHUB_SHA" {}
variable "GITHUB_REPOSITORY" {}
 

target "sampleapp-github" {
  pull       = true
  context    = "."
  dockerfile = "Dockerfile"
  tags       = ["ghcr.io/junaid18183/sampleapp:${GITHUB_SHA}"]
  cache-from = ["type=registry,ref=ghcr.io/junaid18183/sampleapp:cache"]
  cache-to   = ["type=registry,ref=ghcr.io/junaid18183/sampleapp:cache,mode=max"]
  platforms  = ["linux/amd64"]
  labels     = {
    "org.opencontainers.image.title": "${CI_PROJECT_TITLE}",
    "org.opencontainers.image.description": "${CI_PROJECT_TITLE}",
    "org.opencontainers.image.url": "${GITHUB_REPOSITORY}",
    "org.opencontainers.image.source": "${GITHUB_REPOSITORY}",
    "org.opencontainers.image.version": "${GITHUB_SHA}",
    "org.opencontainers.image.created": "${CI_COMMIT_TIMESTAMP}",
    "org.opencontainers.image.revision": "${GITHUB_SHA}",
  }
}