#!/usr/bin/ruby

# encoding: UTF-8
require "/Galaxy/Software/Misc-Common/Ruby-Libraries/LucilleCore.rb"
require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"
require "time"

# -------------------------------------------------------------------------------------

# NSXAgentStreams::getObjects()

class NSXAgentStreams

    # NSXAgentStreams::agentuuid()
    def self.agentuuid()
        "d2de3f8e-6cf2-46f6-b122-58b60b2a96f1"
    end

    # NSXAgentStreams::getObjects()
    def self.getObjects()
        # This agent doesn't generate its own objects but it handles the commands. 
        # The objects are generated by the LightThreads's agent
        # When a command is executed we reload the NSXAgentLightThread's objects
        # NSXAgentLightThread calls the stream objects with the right metric.
        return []
    end

    # NSXAgentStreams::stopObject(object)
    def self.stopObject(object)
        streamItemUUID = object["data"]["stream-item"]["uuid"]
        timespanInSeconds = NSXStreamsUtils::stopStreamItem(streamItemUUID)
        NSXStreamsUtils::stopPostProcessing(streamItemUUID)
        return if timespanInSeconds == 0
        lightThreadUUID = object["data"]["light-thread"]["uuid"]
        #puts "Notification: NSXAgentStreams, adding #{timespanInSeconds} seconds to LightThread '#{object["data"]["light-thread"]["description"]}'"
        NSXLightThreadUtils::addTimeToLightThread(lightThreadUUID, timespanInSeconds)
    end

    # NSXAgentStreams::doneObjectEmailCarrier(object)
    def self.doneObjectEmailCarrier(object)
        claim = NSXEmailTrackingClaims::getClaimByStreamItemUUIDOrNull(object["data"]["stream-item"]["uuid"])
        if claim["status"]=="init" then
            claim["status"] = "deleted-on-local"
            NSXEmailTrackingClaims::commitClaimToDisk(claim)
        end
        if claim["status"]=="detached" then
            claim["status"] = "deleted-on-local"
            NSXEmailTrackingClaims::commitClaimToDisk(claim)
        end
        if claim["status"]=="deleted-on-server" then
            claim["status"] = "dead"
            NSXEmailTrackingClaims::commitClaimToDisk(claim)
        end
        if claim["status"]=="deleted-on-local" then
        end
        if claim["status"]=="dead" then
        end
    end

    # NSXAgentStreams::doneObject(object)
    def self.doneObject(object)
        NSXAgentStreams::stopObject(object)
        # If the object carries a stream item that is an email with a tracking claim, then we need to update the tracking claim
        if object["agentuid"] == "d2de3f8e-6cf2-46f6-b122-58b60b2a96f1" then
            if NSXEmailTrackingClaims::getClaimByStreamItemUUIDOrNull(object["data"]["stream-item"]["uuid"]) then
                NSXAgentStreams::doneObjectEmailCarrier(object)
                return
            end
        end
        NSXStreamsUtils::destroyItem(object["data"]["stream-item"]["filename"])
    end

    def self.processObjectAndCommand(object, command)
        if command == "open" then
            NSXStreamsUtils::viewItem(object["data"]["stream-item"]["filename"])
        end
        if command == "start" then
            NSXRunner::start(object["data"]["stream-item"]["uuid"])
            NSXMiscUtils::setStandardListingPosition(1)
        end
        if command == "stop" then
            NSXAgentStreams::stopObject(object)
        end
        if command == "done" then
            NSXAgentStreams::doneObject(object)
            KeyValueStore::destroy(nil, "8a0790c9-4501-4132-84c5-c772898e5183")
        end
        if command == "time:" then
            timespanInMinutes = LucilleCore::askQuestionAnswerAsString("Time in minutes: ").to_f
            timespanInSeconds = timespanInMinutes*60
            lightThreadUUID = object["data"]["light-thread"]["uuid"]
            lightThreadDescription = object["data"]["light-thread"]["description"]
            puts "Notification: NSXAgentStreams, adding #{timespanInSeconds} seconds to LightThread '#{lightThreadDescription}'"
            NSXLightThreadUtils::addTimeToLightThread(lightThreadUUID, timespanInSeconds)
        end
        if command == "recast" then
            # If the object carries a stream item that is an email with a tracking claim, then we need to update the tracking claim
            if object["agentuid"] == "d2de3f8e-6cf2-46f6-b122-58b60b2a96f1" then
                claim = NSXEmailTrackingClaims::getClaimByStreamItemUUIDOrNull(object["data"]["stream-item"]["uuid"])
                if claim then
                    if claim["status"]=="init" then
                        claim["status"] = "detached"
                        NSXEmailTrackingClaims::commitClaimToDisk(claim)
                    end
                    if claim["status"]=="detached" then
                    end
                    if claim["status"]=="deleted-on-server" then
                    end
                    if claim["status"]=="deleted-on-local" then
                    end
                    if claim["status"]=="dead" then
                    end
                end
            end
            NSXAgentStreams::stopObject(object)
            NSXStreamsUtils::recastStreamItem(object["data"]["stream-item"]["uuid"])
        end
        if command == "push" then
            NSXStreamsUtils::resetRunDataAndRotateItem(object["data"]["light-thread"]["streamuuid"], 5, object["data"]["stream-item"]["uuid"])
        end
        if command == "description:" then
            itemuuid = object["data"]["stream-item"]["uuid"]
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            NSXStreamsUtils::setItemDescription(itemuuid, description)
        end
        if command == "ordinal:" then
            itemuuid = object["data"]["stream-item"]["uuid"]
            ordinal = LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
            NSXStreamsUtils::setItemOrdinal(itemuuid, ordinal)
        end
    end

    def self.interface()

    end

end