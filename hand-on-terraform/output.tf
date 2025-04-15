output "sagemaker_domain_arn" {
  value = aws_sagemaker_domain.sagemaker_domain.arn
}

output "sagemaker_domain_name" {
  value = aws_sagemaker_domain.sagemaker_domain.domain_name
}

######################################################
# 2. (Optional) Output
######################################################
output "sagemaker_space_arn" {
  value = aws_sagemaker_space.bora_jupyterlab_space.arn
}