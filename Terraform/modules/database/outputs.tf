output "db_config" {
  value = {
    user     = aws_docdb_cluster.main.master_username
    password = aws_docdb_cluster.main.master_password
    hostname = aws_docdb_cluster.main.endpoint
    port     = aws_docdb_cluster.main.port
    region   = data.aws_region.current.name
  }
}