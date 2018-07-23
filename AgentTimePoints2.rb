#!/usr/bin/ruby

# encoding: UTF-8

require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"
require 'json'
require 'date'
require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest
require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"
require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv('oldname', 'newname')
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')
require 'find'
require 'json'
require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest
require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"
require_relative "Bob.rb"
# -------------------------------------------------------------------------------------

Bob::registerAgent(
    {
        "agent-name"      => "AgentTimePoints2",
        "agent-uid"       => "201cac75-9ecc-4cac-8ca1-2643e962a6c6",
        "general-upgrade" => lambda { AgentTimePoints2::generalFlockUpgrade() },
        "object-command-processor" => lambda{ |object, command| AgentTimePoints2::processObjectAndCommand(object, command) },
        "interface"       => lambda{ AgentTimePoints2::interface() }
    }
)

class AgentTimePoints2

    def self.agentuuid()
        "201cac75-9ecc-4cac-8ca1-2643e962a6c6"
    end

    def self.interface()
        
    end

    def self.ratioToMetric(ratio)
        ratio = [ratio, 1].min
        0.5 + 0.35*(1-ratio)
    end

    def self.generalFlockUpgrade()
        TheFlock::removeObjectsFromAgent(self.agentuuid())
        Dir.entries("/Galaxy/DataBank/Catalyst/Agents-Data/time-points2")
            .select{|filename| filename[-5, 5]=='.json' }
            .map{|filename| "/Galaxy/DataBank/Catalyst/Agents-Data/time-points2/#{filename}" }
            .map{|filepath| [filepath, JSON.parse(IO.read(filepath))] }
            .map{|data|
                filepath, lisa = data
                # lisa: { :uuid, :unixtime :description, :time-struture }
                uuid = lisa["uuid"]
                description = lisa["description"]
                timestructure = lisa["time-struture"]
                timedoneInHours, timetodoInHours, ratio = TimeStructuresOperator::doneMetricsForTimeStructure(uuid, timestructure)
                metric = self.ratioToMetric(ratio)
                if ratio>1 then
                    metric = 1.5 + CommonsUtils::traceToMetricShift(uuid)
                end
                if Chronos::isRunning(uuid) then
                    metric = 2 + CommonsUtils::traceToMetricShift(uuid)
                end
                object              = {}
                object["uuid"]      = uuid
                object["agent-uid"] = self.agentuuid()
                object["metric"]    = metric 
                object["announce"]  = "time point: #{description} ( #{(100*ratio).round(2)} % of #{timestructure["time-commitment-in-hours"]} hours )"
                object["commands"]  = Chronos::isRunning(uuid) ? ["stop"] : ["start", "add-time", "destroy"]
                object["default-expression"] = Chronos::isRunning(uuid) ? "stop" : "start"
                object["is-running"] = Chronos::isRunning(uuid)
                object["item-data"] = {}
                object["item-data"]["filepath"] = filepath
                object["item-data"]["lisa"] = lisa
                object["item-data"]["ratio"] = ratio
                object                   
            }
            .each{|object|
                if object["item-data"]["ratio"] > 1 then
                    system("terminal-notifier -title 'Catalyst Lisa' -message '#{object["item-data"]["lisa"]["description"]} is done'")
                    sleep 2
                end
                TheFlock::addOrUpdateObject(object) 
            }
    end

    def self.processObjectAndCommand(object, command)
        if command=='start' then
            uuid = object["uuid"]
            Chronos::start(uuid)
        end
        if command=='stop' then
            # To be implemented.            
        end
        if command=="add-time" then
            timeInHours = LucilleCore::askQuestionAnswerAsString("Time in hours: ").to_f
            Chronos::addTimeInSeconds(object["uuid"], timeInHours*3600)
            ProjectsCore::ui_donateTimeSpanInSecondsToInteractivelyChosenProjectLocalCommitmentItem(timeInHours*3600)
        end
        if command=='destroy' 
            filepath = object["item-data"]["filepath"]
            FileUtils.rm(filepath)
        end
    end
end
