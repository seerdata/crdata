# General settings required for the system to run

# Keys for the main CRData Amazon account - read from env!
AWS_ACCESS_KEY = ENV['CRDATA_ACCESS_KEY'] 
AWS_SECRET_KEY = ENV['CRDATA_SECRET_KEY'] 
MAIN_BUCKET    = 'crdataapp'
S3_URL = "http://#{MAIN_BUCKET}.s3.amazonaws.com"
SSL_S3_URL =  "https://#{MAIN_BUCKET}.s3.amazonaws.com"

# Number of items to show per page
ITEMS_PER_PAGE = 20
# 
# Number of items to select to show per page
SELECT_ITEMS_PER_PAGE = 8

# Job statuses
JOB_STATUSES = %w(new submitted running done failed cancelled pending)

#HOSTNAME
CRDATA_HOST = "http://#{YAML.load_file(File.join(Rails.root, 'config', 'settings.yml'))['host']['hostname']}"
#R WORKER AMI
WORKER_IMG = YAML.load_file(File.join(Rails.root, 'config', 'settings.yml'))['host']['worker_image'] 

#AWS 
AWS_PWD  = ENV['AWS_PWD']
AWS_SALT = ENV['AWS_SALT']

#EC2 Security Group Name
EC2_SECURITY_GROUP = 'r_node'

#EC2 availability zones
EC2_AVAILABILITY_ZONES = ['us-east-1a', 'us-east-1b', 'us-east-1c', 'us-east-1d', 'eu-west-1a', 'eu-west-1b']

#Number of tags to show in tag cloud
TAG_CLOUD_SIZE = 20

#Dataset dimensions
DATASET_DIMENSIONS = {'use' => 'Ease of Use', 'speed' => 'Speed of Execution', 'quality' => 'Quality of Docs', 'data' => 'Quality of Data'}

#R script dimensions
R_SCRIPT_DIMENSIONS = {'use' => 'Ease of Use', 'speed' => 'Speed of Execution', 'quality' => 'Quality of Docs', 'reliability' => 'Reliability of Results'}

#Number of rating stars
RATING_STARS = 5
