resource "helm_release" "example_redis" {
  name       = "my-redis-release"
  chart      = "oci://registry-1.docker.io/cloudpirates/redis"
  version    = "0.1.1"

  # Setting values directly
  set = [
    {
      name  = "cluster.enabled"
      value = "true"
    }
  ]

  # Loading values from a YAML file
  values = [
    file("${path.module}/redis.yaml")
  ]
}
