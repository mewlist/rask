#
# Rask library
# (c)2010 mewlist
#
require 'fileutils'
require 'thread'

require File.dirname(__FILE__) + '/rask/state_machine'


module Rask
  
  class Task
    include StateMachine
    attr_accessor :task_id
    attr_accessor :group
    
    def initialize(_group=nil)
      group = _group
      super()
    end
    
    
    def run
      if @state
        eval @state.to_s
      end
    end
    
    
    def transition(to)
      @state = to
    end
    
    
    def destroy
      transition nil
    end
    
    
    def destroy?
      @state == nil
    end
    
  end
  
  
  @@base_dir  = '/tmp/rask'
  @@threading = false
  
  def self.base_directory=(new_directory)
    @@base_dir = new_directory
  end
  
  def self.enable_thread
    @@threading = true
  end
  
  def self.disable_thread
    @@threading = false
  end
  
  def self.insert(task)
    initialize_storage
    task_id = "#{safe_class_name(task.class.name)}-#{task.group.to_s}-#{Time.now.to_i}-#{Time.now.usec}"
    task.task_id = task_id
    FileUtils.touch(task_path(task_id)) unless File.exists? task_path(task_id)
    f = File.open(task_path(task_id), 'w')
    f.flock(File::LOCK_EX)
    Marshal.dump(task, f)
    f.flock(File::LOCK_UN)
    f.close
  end
  
  
  def self.run(task_path)
    f = File.open(task_path, 'r+')
    f.flock(File::LOCK_EX)
    
    task = Marshal.restore(f)
    yield task
    
    f.truncate(0)
    f.pos = 0
    Marshal.dump(task, f)
    f.flock(File::LOCK_UN)
    f.close
    FileUtils.rm(task_path) if task.destroy?
  end
  
  def self.each(options = { :class=>nil, :group=>nil }, &blk)
    threads = []
    tasks(options).each { |d|
      if @@threading
        threads << Thread::new(d) { |task_path| run(task_path, &blk) }
      else
        run(d, &blk)
      end
    }
    threads.each { |t| t.join } if @@threading
  end
  
  def self.tasks(options = { :class=>nil, :group=>nil })
    target = task_dir
    target += '/' if options[:class] || options[:group]
    target += "#{safe_class_name(options[:class])}" if options[:class]
    target += "-#{options[:group]}-" if options[:group]
    
    task_list = []
    Dir.glob(task_dir+"/*.task") { |d|
      if target.empty? || /#{target}/ =~ d
        task_list.push d
      end
    }
    task_list
  end
  
  def self.task_dir
    @@base_dir
  end
  
  def self.task_path(task_id)
    task_dir+"/#{task_id}.task"
  end
  
  def self.initialize_storage
    unless File.exists? @@base_dir
      FileUtils.makedirs @@base_dir
    end
  end
  
  def self.destroy(task)
    FileUtils.rm(task_path(task.task_id)) if File.exists? task_path(task.task_id)
  end
  
  def self.safe_class_name(c)
    c.gsub(/[:]/,'@')
  end
  
  def self.daemon(options = { :class=>nil, :group=>nil, :sleep=>1 })
    exit if fork
    Process.setsid
    open(task_dir+"/Rask.pid","w"){|f| f.write Process.pid}
    while true
      Rask.each { |task|
        task.run
      }
      sleep(options[:sleep])
    end
  end
  
  
end





