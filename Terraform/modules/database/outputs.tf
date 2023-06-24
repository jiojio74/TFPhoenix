output "db_config" {
  value = {
    user     = aws_db_instance.database.username
    password = aws_db_instance.database.password
    database = aws_db_instance.database.db_name
    hostname = aws_db_instance.database.address
    port     = aws_db_instance.database.port
  }
}

output "docdb_config" {
  value = {
    user     = aws_docdb_cluster.main.master_username
    password = aws_docdb_cluster.main.master_password
    hostname = aws_docdb_cluster.main.endpoint
    port     = aws_docdb_cluster.main.port
    ssl_reg  = data.aws_region.current.name
  }
}
