# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#   
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Major.create(:name => 'Daley', :city => cities.first)

# Roles
Role.create(:name => 'Owner')
Role.create(:name => 'Admin')
Role.create(:name => 'User')

#Actions
Action.create(:name => 'create')
Action.create(:name => 'update')
Action.create(:name => 'use')
Action.create(:name => 'delete')

=begin
# RScripts
Dir.glob('test/fixtures/*.r').each{|r| RScript.create(:name => r[14..-3], :effort_level => 10, :description => r, :source_code => File.read(r))}

# DataSets
(1..10).each{|d| DataSet.create(:data_location => "Data #{d}", :name => "Data #{d}", :description => "Data #{d}", :data_size => d * 1000, :num_records => d * 10, :data => File.open(File.join(Rails.root, 'test', 'fixtures', 'data.txt')) ) }

# JobsQueue
jobs_queue = JobsQueue.create(:name => 'Default Queue')

# Jobs
rs = RScript.all
ds = DataSet.all
# New jobs
(1..5).each{|j| Job.create(:description => 'New job', :r_script => rs[rand(rs.size)]).data_sets << ds[rand(ds.size)] }
# Submitted jobs
(1..20).each{|j| j = Job.create(:description => 'Submitted job', :r_script => rs[rand(rs.size)]); j.data_sets << ds[rand(ds.size)]; j.submit}


# ProcessingNode
ProcessingNode.create(:jobs_queue_id => jobs_queue, :ip_address => '127.0.0.1', :status => 'activated')
=end 
