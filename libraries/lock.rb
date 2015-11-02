require 'timeout'
require 'thread'


class Chef
  class Recipe
    class LocksmithTimeoutException < Exception
    end
  end
end

class Chef
  class Recipe
    class Locksmith
      # s safe for threads. This module i
      def initialize (aws_access_key_id,aws_secret_access_key,lock_table_name)
        require 'aws-sdk-v1'
        @aws_access_key_id = aws_access_key_id
        @aws_secret_access_key = aws_secret_access_key
        @lock_table = lock_table_name
        @dynamo_lock = Mutex.new
        @table_lock = Mutex.new
      end



      def lock(name, opts={})
        opts[:ttl] ||= 60
        opts[:attempts] ||= 10
        opts[:wait_time] ||= 100 # miliseconds
        # Clean up expired locks. Does not grantee that we will
        # be able to acquire the lock, just a nice thing to do for
        # the other processes attempting to lock.

        if create(name, opts)
          begin Timeout::timeout(opts[:ttl]) {return(yield)}
          ensure delete(name)
          end
        else
          # Couldn't get lock
          raise LocksmithTimeoutException #, "Could not get lock after #{opts[:attempts]} tries with #{opts[:wait_time] miliseconds between each attempt}}"
        end
      end

      def create(name, opts={})
        opts[:ttl] ||= 60
        opts[:attempts] ||= 10
        opts[:wait_time] ||= 100 # miliseconds
        delete(name) if expired?(name, opts[:ttl])
        attempts= opts[:attempts]
        attempts.times do |i|
          begin
            locks.put({"Name" => name, "Created" => Time.now.to_i},
              :unless_exists => "Name")
            return(true)
          rescue AWS::DynamoDB::Errors::ConditionalCheckFailedException
            return(false) if i == (attempts - 1)
          end
          sleep (opts[:wait_time] / 1000)
        end
      end

      def delete(name)
        locks.at(name).delete
      end

      def expired?(name, ttl)
        if l = locks.at(name).attributes.to_h(:consistent_read => true)
          if t = l["Created"]
            t < (Time.now.to_i - ttl)
          end
        end
      end

      def locks
        table(lock_table)
      end

      def table(name)
        unless tables[name]
          @table_lock.synchronize do
            tables[name] = dynamo.tables[name].load_schema
          end
        end
        tables[name].items
      end

      def tables
        @tables ||= {}
      end

      def dynamo
        @dynamo_lock.synchronize do
          @db ||= AWS::DynamoDB.new(:access_key_id => @aws_access_key_id,
                                    :secret_access_key => @aws_secret_access_key)
        end
      end

      def lock_table
        @lock_table
      end

      def lock_table=(table_name)
        @lock_table = table_name
      end
    end
  end
end
