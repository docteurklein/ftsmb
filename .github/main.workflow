workflow "Run gcloud Login" {
  on = "push"
  resolves = "Load credentials"
}

action "Setup Google Cloud" {
  uses = "docker://github/gcloud-auth"
  secrets = ["GCLOUD_AUTH"]
}

action "Load credentials" {
  needs = ["Setup Google Cloud"]
  uses = "docker://github/gcloud"
  args = "container clusters get-credentials example-project --zone us-central1-a --project data-services-engineering"
}
