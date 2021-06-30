data "aws_s3_bucket" "bucket" {
  bucket = var.s3_bucket
}

# See https://aws.amazon.com/blogs/security/writing-iam-policies-how-to-grant-access-to-an-amazon-s3-bucket/
 
resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = data.aws_s3_bucket.bucket.id
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": "*",
      "Action": ["s3:GetObject"],
      "Resource": "${data.aws_s3_bucket.bucket.arn}/*"
    },
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {"AWS": ["arn:aws:iam::364518226878:root"]},
      "Action": [
        "s3:PutObject", 
        "s3:GetObject", 
        "s3:DeleteObject"
      ],
      "Resource":"${data.aws_s3_bucket.bucket.arn}/*"
    }
  ]
}
POLICY
}

# resource "aws_s3_bucket_policy" "bucket_user_policy" {
#   bucket = data.aws_s3_bucket.bucket.id
#   policy = <<POLICY
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Action": [
#         "s3:GetBucketLocation",
#         "s3:ListAllMyBuckets"
#       ],
#       "Resource": "*"
#     },
#     {
#       "Effect": "Allow",
#       "Action": ["s3:ListBucket"],
#       "Resource": ["${data.aws_s3_bucket.bucket.arn}"]
#     },
#     {
#       "Effect": "Allow",
#       "Action": [
#         "s3:PutObject",
#         "s3:GetObject",
#         "s3:DeleteObject"
#       ],
#       "Resource": ["${data.aws_s3_bucket.bucket.arn}/*"]
#     }
#   ]
# }
# POLICY
# }
