# app/services/s3_uploader.rb
require 'aws-sdk-s3'

class S3Uploader
  def self.upload(file, filename)
    s3 = Aws::S3::Resource.new(
      region: ENV['AWS_REGION'],
      credentials: Aws::Credentials.new(
        ENV['AWS_ACCESS_KEY_ID'],
        ENV['AWS_SECRET_ACCESS_KEY']
      )
    )

    obj = s3.bucket(ENV['S3_BUCKET_NAME']).object(filename)
    obj.upload_file(file.path)
    obj.public_url
  end

  def self.delete(old_filename)
    s3 = Aws::S3::Resource.new(
      region: ENV['AWS_REGION'],
      credentials: Aws::Credentials.new(
        ENV['AWS_ACCESS_KEY_ID'],
        ENV['AWS_SECRET_ACCESS_KEY']
      )
    )

    obj = s3.bucket(ENV['S3_BUCKET_NAME']).object(old_filename)
    obj.delete if obj.exists?
  end
end
