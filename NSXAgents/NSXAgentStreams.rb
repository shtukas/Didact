#!/usr/bin/ruby

# encoding: UTF-8
require "/Galaxy/Software/Misc-Common/Ruby-Libraries/LucilleCore.rb"
require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"
require "time"

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/Torr.rb"
=begin
    Torr::event(repositorylocation, collectionuuid, mass)
    Torr::weight(repositorylocation, collectionuuid, stabililityPeriodInSeconds, simulationWeight = 0)
    Torr::metric(repositorylocation, collectionuuid, stabililityPeriodInSeconds, targetWeight, metricAtZero, metricAtTarget)
=end

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

# -------------------------------------------------------------------------------------

$CATALYST_OBJECTS_CACHE_39192FFA = nil

def _68c8f015_removeObjectFromCache(uuid)
    $CATALYST_OBJECTS_CACHE_39192FFA = $CATALYST_OBJECTS_CACHE_39192FFA.reject{|o| o["uuid"]==uuid }
end

def _68c8f015_updateCacheWithNewlyIssuedCatalystObject(uuid)
    item = NSXStreamsUtils::getItemByUUIDOrNull(uuid)
    return if item.nil?
    catalystObject = NSXStreamsUtils::itemToCatalystObject(item)
    _68c8f015_removeObjectFromCache(uuid)
    $CATALYST_OBJECTS_CACHE_39192FFA = $CATALYST_OBJECTS_CACHE_39192FFA + [ catalystObject ]
end

class NSXAgentStreams

    # NSXAgentStreams::agentuuid()
    def self.agentuuid()
        "d2de3f8e-6cf2-46f6-b122-58b60b2a96f1"
    end

    # NSXAgentStreams::getObjects()
    def self.getObjects()
        if $CATALYST_OBJECTS_CACHE_39192FFA and ($CATALYST_OBJECTS_CACHE_39192FFA.size != 0) then
            $CATALYST_OBJECTS_CACHE_39192FFA.map{|o| o.clone }
        else
            objects = NSXStreamsUtils::getCatalystObjectsForDisplay()
            $CATALYST_OBJECTS_CACHE_39192FFA = objects.map{|o| o.clone }
            KeyValueStore::set(nil, "4f66bad9-d8e7-4645-bbc3-0d99e16a6235", JSON.generate(objects))
            objects
        end
    end

    # NSXAgentStreams::getAllObjects()
    def self.getAllObjects()
        NSXStreamsUtils::getAllCatalystObjects()
    end

    # NSXAgentStreams::stopStreamItem(item): item
    def self.stopStreamItem(item)
        return item if item.nil?
        return item if !NSXRunner::isRunning?(item["uuid"])
        runningTimeInSeconds = NSXRunner::stop(item["uuid"])
        puts "Adding #{runningTimeInSeconds} seconds to stream: #{item["streamuuid"]}"
        NSXStreamsTimeTracking::addTimeInSecondsToStream(item["streamuuid"], runningTimeInSeconds)
    end

    # NSXAgentStreams::doneStreamItemEmailCarrier(itemuuid)
    def self.doneStreamItemEmailCarrier(itemuuid)
        claim = NSXEmailTrackingClaims::getClaimByStreamItemUUIDOrNull(itemuuid)
        return if claim.nil?
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

    # NSXAgentStreams::processObjectAndCommand(item, command)
    def self.processObjectAndCommand(item, command)
        if command == "open" then
            genericContentItem = NSXGenericContents::viewGenericContentItemReturnUpdatedItemOrNull(item["generic-content-item"])
            if genericContentItem then
                item["generic-content-item"] = genericContentItem
                NSXStreamsUtils::commitItemToDisk(item)
            end
            return
        end
        if command == "folder" then
            folderpath = NSXGenericContents::resolveFoldernameToFolderpathOrNull(item["generic-content-item"]["parent-foldername"])
            return if folderpath.nil?
            system("open '#{folderpath}'")
            return
        end
        if command == "start" then
            NSXRunner::start(item["uuid"])
            NSXMiscUtils::setStandardListingPosition(1)
            _68c8f015_updateCacheWithNewlyIssuedCatalystObject(item["uuid"])
            return
        end
        if command == "stop" then
            NSXAgentStreams::stopStreamItem(item)
            _68c8f015_removeObjectFromCache(item["uuid"])
            return
        end
        if command == "done" then
            NSXAgentStreams::stopStreamItem(item)
            NSXAgentStreams::doneStreamItemEmailCarrier(item["uuid"])
            NSXStreamsUtils::destroyItem(item)
            _68c8f015_removeObjectFromCache(item["uuid"])
            return
        end
        if command == "recast" then
            # If the item carries a stream item that is an email with a tracking claim, then we need to update the tracking claim
            if item["agentuid"] == "d2de3f8e-6cf2-46f6-b122-58b60b2a96f1" then
                claim = NSXEmailTrackingClaims::getClaimByStreamItemUUIDOrNull(item["uuid"])
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
            NSXAgentStreams::stopStreamItem(item)
            item = NSXStreamsUtils::recastStreamItem(item)
            NSXStreamsUtils::commitItemToDisk(item)
            _68c8f015_removeObjectFromCache(item["uuid"])
            return
        end
        if command == "push" then
            options = [
                "put to position 6 on stream",
                "put to end of stream"
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
            if option == "put to position 6 on stream" then
                item["ordinal"] = NSXStreamsUtils::newPositionNOrdinalForStreamItem(item["streamuuid"], 6, item["uuid"])
                NSXStreamsUtils::commitItemToDisk(item)
            end
            if option == "put to end of stream" then
                item["ordinal"] = NSXMiscUtils::makeEndOfQueueStreamItemOrdinal()
                NSXStreamsUtils::commitItemToDisk(item)
            end
            _68c8f015_removeObjectFromCache(item["uuid"])
            return
        end
    end
end

begin
    $CATALYST_OBJECTS_CACHE_39192FFA = JSON.parse(KeyValueStore::getOrNull(nil, "4f66bad9-d8e7-4645-bbc3-0d99e16a6235"))
rescue
end

Thread.new {
    loop {
        sleep 300
        objects = NSXStreamsUtils::getCatalystObjectsForDisplay()
        $CATALYST_OBJECTS_CACHE_39192FFA = objects.map{|o| o.clone }
        KeyValueStore::set(nil, "4f66bad9-d8e7-4645-bbc3-0d99e16a6235", JSON.generate(objects))
    }
}
