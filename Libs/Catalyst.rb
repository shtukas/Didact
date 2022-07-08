# encoding: UTF-8

class Catalyst

    # Catalyst::itemsForSection1()
    def self.itemsForSection1()
        [
            NxFrames::itemsForSection1(),
            TxProjects::itemsForSection1(),
        ]   
            .flatten
    end

    # Catalyst::itemsForSection2()
    def self.itemsForSection2()
        items = 
            if Time.new.hour < 6 or Time.new.hour > 17 then
                [
                    # Together in the morning
                    Waves::itemsForListing(true),
                    Waves::itemsForListing(false),

                    Streaming::listingItemForAnHour(), # Only out of hours

                    Anniversaries::itemsForListing(),
                    NxFrames::itemsForSection2(),
                    TxDateds::itemsForListing(),
                    TxProjects::itemsForSection2(),
                    TxQueues::itemsForMainListing(),
                    NxTasks::itemsForMainListing(),
                ]
                    .flatten
            else
                [
                    JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Binaries/fitness ns16s`), # day only
                    Anniversaries::itemsForListing(),
                    NxFrames::itemsForSection2(),
                    Waves::itemsForListing(true),
                    TxDateds::itemsForListing(),
                    TxProjects::itemsForSection2(),
                    TxQueues::itemsForMainListing(),
                    NxTasks::itemsForMainListing(),
                    Waves::itemsForListing(false),
                ]
                    .flatten
            end

        items = items
                    .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
                    .select{|item| InternetStatus::itemShouldShow(item["uuid"]) }

        if items.size == 0 then
            items = Streaming::listingItemInfinity()
        end

        items
    end

    # Catalyst::printListing(floatingItems, runningItems, priority, stratification)
    def self.printListing(floatingItems, runningItems, priority, stratification)
        system("clear")

        vspaceleft = CommonUtils::screenHeight()-3

        if Machines::isLucille20() then
            reference = The99Percent::getReference()
            current   = The99Percent::getCurrentCount()
            ratio     = current.to_f/reference["count"]
            line      = "👩‍💻 🔥 #{current} #{ratio} ( #{reference["count"]} @ #{reference["datetime"]} )"
            puts ""
            puts line
            vspaceleft = vspaceleft - 2
            if ratio < 0.99 then
                The99Percent::issueNewReference()
                return
            end
        end

        store = ItemStore.new()

        if !InternetStatus::internetIsActive() then
            puts "INTERNET IS OFF".green
            vspaceleft = vspaceleft - 2
        end

        puts ""
        vspaceleft = vspaceleft - 1
        floatingItems
            .each{|item|
                store.register(item, false)
                line = "#{store.prefixString()} #{LxFunction::function("toString", item)}".yellow
                if NxBallsService::isActive(item["uuid"]) then
                    line = "#{line} (#{NxBallsService::activityStringOrEmptyString("", item["uuid"], "")})".green
                end
                puts line
                vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
            }

        running = NxBallsIO::getItems().select{|nxball| !runningItems.map{|item| item["uuid"] }.include?(nxball["uuid"]) }
        if running.size > 0 then
            puts ""
            vspaceleft = vspaceleft - 1
            running
                .sort{|t1, t2| t1["unixtime"] <=> t2["unixtime"] }
                .each{|nxball|
                    store.register(nxball, false)
                    line = "#{store.prefixString()} [running] #{nxball["description"]} (#{NxBallsService::activityStringOrEmptyString("", nxball["uuid"], "")})"
                    puts line.green
                    vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
                }
        end

        content = IO.read("/Users/pascal/Desktop/top.txt").strip
        if content.size > 0 then
            top = content.lines.first(10).select{|line| line.strip.size > 0 }.join.strip
            if top.size > 0 then
                puts ""
                puts "top:"
                puts top.green
                vspaceleft = vspaceleft - (CommonUtils::verticalSize(top) + 2)
            end
        end

        ordinals = NxOrdinals::itemsForListing()
        if ordinals.size > 0 then
            puts ""
            puts "ordinals:"
            vspaceleft = vspaceleft - 2
            ordinals.each{|ordinal|
                store.register(ordinal, false)
                line = "#{store.prefixString()} #{NxOrdinals::toString(ordinal)}"
                puts line.green
                vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
            }
        end

        printSection = lambda {|section, store|
            section
                .each{|item|
                    store.register(item, true)
                    line = LxFunction::function("toString", item)
                    line = "#{store.prefixString()} #{line}"
                    break if (vspaceleft - CommonUtils::verticalSize(line)) < 0
                    if NxBallsService::isActive(item["uuid"]) then
                        line = "#{line} (#{NxBallsService::activityStringOrEmptyString("", item["uuid"], "")})".green
                    end
                    puts line
                    vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
                }
        }

        puts ""
        vspaceleft = vspaceleft - 1
        printSection.call(runningItems, store)
        printSection.call(priority, store)

        puts ""
        stratification
                .each{|nxStratificationItem|
                    item = nxStratificationItem["item"]
                    store.register(item, true)
                    line = "(ord: #{"%5.2f" % nxStratificationItem["ordinal"]}) #{LxFunction::function("toString", item)}"
                    line = "#{store.prefixString()} #{line}"
                    break if (vspaceleft - CommonUtils::verticalSize(line)) < 0
                    if NxBallsService::isActive(item["uuid"]) then
                        line = "#{line} (#{NxBallsService::activityStringOrEmptyString("", item["uuid"], "")})".green
                    end
                    puts line
                    vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
                }

        puts ""
        input = LucilleCore::askQuestionAnswerAsString("> ")

        return if input == ""

        if input.start_with?("+") and (unixtime = CommonUtils::codeToUnixtimeOrNull(input.gsub(" ", ""))) then
            if (item = store.getDefault()) then
                NxBallsService::close(item["uuid"], true)
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
                return
            end
        end

        Commands::run(input, store)
    end

    # Catalyst::program2()
    def self.program2()

        initialCodeTrace = CommonUtils::generalCodeTrace()
 
        if Machines::isLucille20() then 
            Thread.new {
                loop {
                    sleep 3600
                    system("#{File.dirname(__FILE__)}/operations/vienna-import")
                }
            }
        end

        EventsToAWSQueue::sync(true)

        Thread.new {
            loop {
                sleep 60
                EventsToAWSQueue::sync(false)
            }
        }

        loop {

            #puts "(code trace)"
            if CommonUtils::generalCodeTrace() != initialCodeTrace then
                puts "Code change detected"
                break
            end

            #puts "(NxTasks-Inbox)"
            LucilleCore::locationsAtFolder("/Users/pascal/Desktop/NxTasks-Inbox").each{|location|
                item = NxTasks::issueFromInboxLocation(location)
                puts JSON.pretty_generate(item)
                LucilleCore::removeFileSystemLocation(location)
            }

            #puts "(floatingItems)"
            floatingItems = Catalyst::itemsForSection1()

            #puts "(section2) 1"
            section2 = Catalyst::itemsForSection2()

            #puts "(section2) 4"
            runningItems, section2 = section2.partition{|item| NxBallsService::isActive(item["uuid"]) }

            priorityMikuTypes = ["fitness1"]

            priority, section2 = section2.partition{|item| priorityMikuTypes.include?(item["mikuType"]) }

            # --------------------------------------------------------------------------------------------
            # stratification

            #{
            #    "ordinal"   : Float
            #    "mikuType"  : "NxStratificationItem"
            #    "item"      : Item
            #    "keepAlive" : Boolean # reset to false at start of replacement process and then to true indicating that the item has been replaced.
            #}

            # stratification : Array[NxStratificationItem]

            digest = lambda {|stratification, item|
                hasBeenReplaced = false
                stratification = stratification.map{|i|
                    if i["item"]["uuid"] == item["uuid"] then
                        i["item"] = item
                        i["keepAlive"] = true
                        hasBeenReplaced = true
                    end
                    i
                }
                if !hasBeenReplaced then
                    ordinal = ([0] + stratification.map{|nx| nx["ordinal"]}).max + 1
                    nxStratificationItem = {
                        "ordinal"   => ordinal,
                        "mikuType"  => "NxStratificationItem",
                        "item"      => item,
                        "keepAlive" => true
                    }
                    stratification = stratification + [nxStratificationItem]
                end
                stratification
            }

            # --------------------------------------

            stratification = JSON.parse(IO.read("/Users/pascal/Galaxy/DataBank/Stargate/catalyst-stratification.json"))

            # reset all keepAlive
            stratification = stratification.map{|item|
                item["keepAlive"] = false
                item
            }

            stratification = section2.reduce(stratification) {|strat, item|
                digest.call(strat, item)
            }

            stratification = stratification.select{|item| item["keepAlive"]}

            stratification = stratification.sort{|i1, i2| i1["ordinal"] <=> i2["ordinal"] }

            File.open("/Users/pascal/Galaxy/DataBank/Stargate/catalyst-stratification.json", "w") {|f| f.puts(JSON.pretty_generate(stratification)) }

            # --------------------------------------------------------------------------------------------

            #puts "(Catalyst::printListing)"
            Catalyst::printListing(floatingItems, runningItems, priority, stratification)
        }
    end
end
