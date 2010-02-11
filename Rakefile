require 'rubygems'
gem 'hoe', '>= 2.1.0'
require 'hoe'
require File.dirname(__FILE__) + '/lib/rask.rb'

Hoe.plugin :newgem
# Hoe.plugin :website
# Hoe.plugin :cucumberfeatures

# Generate all the Rake tasks
# Run 'rake -T' to see list of generated tasks (from gem root directory)
$hoe = Hoe.spec 'rask' do
  self.developer 'mewlist', 'mewlist@mewlist.com'
#  self.post_install_message = 'PostInstall.txt'
  self.rubyforge_name       = self.name
  # self.extra_deps         = [['activesupport','>= 2.0.2']]

end

require 'newgem/tasks'
Dir['tasks/**/*.rake'].each { |t| load t }

# TODO - want other tests/tasks run by default? Add them to the list
# remove_task :default
# task :default => [:spec, :features]
