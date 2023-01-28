# encoding: UTF-8

class CatalystListing

    # CatalystListing::listingCommands()
    def self.listingCommands()
        [
            "[listing interaction] .. | <datecode> | access (<n>) | do not show until <n> | done (<n>) | edit (<n>) | expose (<n>) | probe (<n>) | >> skip default | destroy",
            "[makers] wave | anniversary | today | ondate | todo | timedrop | fiber | manual countdown | top | strat | block",
            "[nxballs] start (<n>) | stop <n> | pause <n> | pursue <n>",
            "[divings] anniversaries | ondates | waves | fibers | todos",
            "[transmutations] '' (transmute)",
            "[misc] require internet | search | speed | commands | lock (<n>) | numbers",
        ].join("\n")
    end

    # CatalystListing::listingCommandInterpreter(input, store)
    def self.listingCommandInterpreter(input, store)

        if input.start_with?("+") and (unixtime = CommonUtils::codeToUnixtimeOrNull(input.gsub(" ", ""))) then
            if (item = store.getDefault()) then
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
                return
            end
        end

        if Interpreting::match("..", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::doubleDotAccess(item)
            return
        end

        if Interpreting::match(".. *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyActions::doubleDotAccess(item)
            return
        end

        if Interpreting::match("''", input) then
            item = store.getDefault()
            return if item.nil?
            puts JSON.pretty_generate(item)
            Transmutations::transmute2(item)
            return
        end

        if Interpreting::match("access", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::access(item)
            return
        end

        if Interpreting::match("access *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyActions::access(item)
            return
        end

        if Interpreting::match("anniversary", input) then
            Anniversaries::issueNewAnniversaryOrNullInteractively()
            return
        end

        if Interpreting::match("anniversaries", input) then
            Anniversaries::mainprobe()
            return
        end

        if Interpreting::match("numbers", input) then
            CatalystListing::displayNumbers()
            return
        end

        if Interpreting::match("commands", input) then
            puts CatalystListing::listingCommands().yellow
            LucilleCore::pressEnterToContinue()
            return
        end

        if Interpreting::match("destroy", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::destroyWithPrompt(item)
            return
        end

        if Interpreting::match("destroy *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyActions::destroyWithPrompt(item)
            return
        end

        if Interpreting::match("done", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::done(item)
            return
        end

        if Interpreting::match("done *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyActions::done(item)
            return
        end

        if Interpreting::match("do not show until *", input) then
            _, _, _, _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            datecode = LucilleCore::askQuestionAnswerAsString("datecode: ")
            return if datecode == ""
            unixtime = CommonUtils::codeToUnixtimeOrNull(datecode.gsub(" ", ""))
            return if unixtime.nil?
            DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
            return
        end

        if Interpreting::match("edit", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::edit(item)
            return
        end

        if Interpreting::match("edit *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyActions::edit(item)
            return
        end

        if Interpreting::match("exit", input) then
            exit
        end

        if Interpreting::match("expose", input) then
            item = store.getDefault()
            return if item.nil?
            puts JSON.pretty_generate(item)
            LucilleCore::pressEnterToContinue()
            return
        end

        if Interpreting::match("expose *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            puts JSON.pretty_generate(item)
            LucilleCore::pressEnterToContinue()
            return
        end

        if Interpreting::match("strat", input) then
            TxStratospheres::interactivelyIssueOrNull()
            return
        end

        if Interpreting::match("internet off", input) then
            InternetStatus::setInternetOff()
            return
        end

        if Interpreting::match("internet on", input) then
            InternetStatus::setInternetOn()
            return
        end

        if Interpreting::match("lock", input) then
            item = store.getDefault()
            return if item.nil?
            domain = LucilleCore::askQuestionAnswerAsString("domain: ")
            Locks::lock(domain, item["uuid"])
            return
        end

        if Interpreting::match("manual countdown", input) then
            TxManualCountDowns::issueNewOrNull()
            return
        end

        if Interpreting::match("ondate", input) then
            item = NxOndates::interactivelyIssueNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("ondates", input) then
            NxOndates::report()
            return
        end

        if Interpreting::match("timedrop", input) then
            NxTimeDrops::interactivelyIssueNewOrNull()
            return
        end

        if Interpreting::match("probe", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::probe(item)
            return
        end

        if Interpreting::match("probe *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyActions::probe(item)
            return
        end

        if Interpreting::match("pause *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            if item["mikuType"] == "Nxball" then
                NxBalls::pause(item)
                return
            end
            nxball = NxBalls::getNxBallForItemOrNull(item)
            if nxball then
                NxBalls::pause(nxball)
                return
            end
            return
        end

        if Interpreting::match("block", input) then
            item = NxBlocks::interactivelyIssueOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("pursue *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            if item["mikuType"] == "Nxball" then
                NxBalls::pursue(item)
                return
            end
            nxball = NxBalls::getNxBallForItemOrNull(item)
            if nxball then
                NxBalls::pursue(nxball)
                return
            end
            return
        end

        if Interpreting::match("require internet", input) then
            item = store.getDefault()
            return if item.nil?
            InternetStatus::markIdAsRequiringInternet(item["uuid"])
            return
        end

        if Interpreting::match("search", input) then
            SearchCatalyst::run()
            return
        end

        if Interpreting::match("start", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::start(item)
            return
        end

        if Interpreting::match("start *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyActions::start(item)
            return
        end

        if Interpreting::match("stop", input) then
            item = store.getDefault()
            return if item.nil?

            if item["mikuType"] == "NxBall" then
                NxBalls::close(item)
                return
            else
                nxball = NxBalls::getNxBallForItemOrNull(item)
                if nxball then
                    NxBalls::close(nxball)
                end
            end
            return
        end

        if Interpreting::match("stop *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?

            if item["mikuType"] == "NxBall" then
                NxBalls::close(item)
                return
            else
                nxball = NxBalls::getNxBallForItemOrNull(item)
                if nxball then
                    NxBalls::close(nxball)
                end
            end
            return
        end

        if Interpreting::match(">>", input) then
            item = store.getDefault()
            return if item.nil?
            Skips::skip(item["uuid"], Time.new.to_f + 3600*1.5)
            return
        end

        if Interpreting::match("today", input) then
            item = NxOndates::interactivelyIssueNewTodayOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("todo", input) then
            item = NxTodos::interactivelyIssueNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("top", input) then
            item = NxTops::interactivelyIssueNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if input == "wave" then
            Waves::issueNewWaveInteractivelyOrNull()
            return
        end

        if input == "waves" then
            Waves::dive()
            return
        end

        if Interpreting::match("fiber", input) then
            NxTimeFibers::interactivelyIssueNewOrNull()
            return
        end

        if Interpreting::match("fibers", input) then
            NxTimeFibers::mainprobe()
            return
        end

        if Interpreting::match("speed", input) then
            CatalystListing::runSpeedTest()
            LucilleCore::pressEnterToContinue()
            return
        end
    end

    # CatalystListing::runSpeedTest()
    def self.runSpeedTest()
        tests = [
            {
                "name" => "Anniversaries::listingItems()",
                "lambda" => lambda { Anniversaries::listingItems() }
            },
            {
                "name" => "NxTimeFibers::listingElements(true)",
                "lambda" => lambda { NxTimeFibers::listingElements(true) }
            },
            {
                "name" => "NxTimeFibers::listingElements(false)",
                "lambda" => lambda { NxTimeFibers::listingElements(false) }
            },
            {
                "name" => "NxOndates::listingItems()",
                "lambda" => lambda { NxOndates::listingItems() }
            },
            {
                "name" => "TodoDatabase2::itemsForMikuType(NxTriage)",
                "lambda" => lambda { TodoDatabase2::itemsForMikuType("NxTriage") }
            },
            {
                "name" => "NxTimeDrops::listingItems()",
                "lambda" => lambda { NxTimeDrops::listingItems() }
            },
            {
                "name" => "source code trace generation",
                "lambda" => lambda { CommonUtils::stargateTraceCode() }
            },
            {
                "name" => "The99Percent::getCurrentCount()",
                "lambda" => lambda { The99Percent::getCurrentCount() }
            },
            {
                "name" => "TxManualCountDowns::listingItems()",
                "lambda" => lambda { TxManualCountDowns::listingItems() }
            },
            {
                "name" => "Waves::listingItems(ns:beach)",
                "lambda" => lambda { Waves::listingItems("ns:beach") }
            },
            {
                "name" => "Waves::listingItems(ns:mandatory-today)",
                "lambda" => lambda { Waves::listingItems("ns:mandatory-today") }
            },
            {
                "name" => "Waves::listingItems(ns:time-important)",
                "lambda" => lambda { Waves::listingItems("ns:time-important") }
            },
        ]

        runTest = lambda {|test|
            t1 = Time.new.to_f
            (1..3).each{ test["lambda"].call() }
            t2 = Time.new.to_f
            {
                "name" => test["name"],
                "runtime" => (t2 - t1).to_f/3
            }
        }

        printTestResults = lambda{|result, padding|
            puts "- #{result["name"].ljust(padding)} : #{"%6.3f" % result["runtime"]}"
        }

        padding = tests.map{|test| test["name"].size }.max

        # dry run to initialise things
        tests
            .each{|test|
                test["lambda"].call()
            }

        results = tests
                    .map{|test|
                        puts "running: #{test["name"]}"
                        runTest.call(test)
                    }
                    .sort{|r1, r2| r1["runtime"] <=> r2["runtime"] }
                    .reverse

        puts ""
        results
            .each{|result|
                printTestResults.call(result, padding)
            }

        puts ""
        printTestResults.call(runTest.call({
            "name" => "CatalystListing::listingItems()",
            "lambda" => lambda { CatalystListing::listingItems() }
        }), padding)
    end

    # CatalystListing::listingItems()
    def self.listingItems()
        items = [
            TodoDatabase2::itemsForMikuType("NxTriage"),
            Anniversaries::listingItems(),
            Waves::listingItems("ns:mandatory-today"),
            NxOndates::listingItems(),
            TxManualCountDowns::listingItems(),
            NxTimeDrops::items(),
            NxTimeFibers::listingElements(true),
            Waves::listingItems("ns:time-important"),
            NxTimeFibers::listingElements(false),
            NxBlocks::listingItems(3),
            Waves::listingItems("ns:beach"),
            NxBlocks::listingItems(6),
        ]
            .flatten
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|item| InternetStatus::itemShouldShow(item["uuid"]) }
    end

    # CatalystListing::printItem(store, item, canBeDefault, prefix)
    def self.printItem(store, item, canBeDefault, prefix)
        store.register(item, canBeDefault)
        tc = NxTimeFibers::getOrNull(item["tcId"])
        tcStr = tc ? " [#{"fiber:".green} #{tc["description"]}]" : ""
        line = "(#{store.prefixString()})#{tcStr} #{prefix}#{PolyFunctions::toStringForCatalystListing(item)}"
        nxball = NxBalls::getNxBallForItemOrNull(item)
        if nxball then
            line = "#{line} #{NxBalls::toRunningStatement(nxball)}".green
        end
        line = "#{line}"
        puts line
        CommonUtils::verticalSize(line)
    end

    # CatalystListing::getItemFromItemsOrNull(items, uuid)
    def self.getItemFromItemsOrNull(items, uuid)
        items.select{|item| item["uuid"] == uuid }.first
    end

    # CatalystListing::nxballHasAnItemInThere(nxball, listingItems)
    def self.nxballHasAnItemInThere(nxball, listingItems)
        itemuuid = nxball["itemuuid"]
        return false if itemuuid.nil?
        listingItems.any?{|item| item["uuid"] == itemuuid }
    end

    # CatalystListing::fibersAndDropsTimePendingInSeconds()
    def self.fibersAndDropsTimePendingInSeconds()
        hours1 = NxTimeFibers::allPendingTimeTodayInHoursLive()*3600
        hours2 = NxTimeDrops::allPendingTimeTodayInHoursLive()*3600
        hours1 + hours2
    end

    # CatalystListing::displayNumbers()
    def self.displayNumbers()

        listingItems = CatalystListing::listingItems()

        fibersAndDropsTimeInSeconds = CatalystListing::fibersAndDropsTimePendingInSeconds()
        timeMiscInSeconds = listingItems
            .select{|item| ["NxTimeDrop", "NxTimeFiber", "NxTodo"].include?(item["mikuType"]) } # fibersAndDropsTimeInSeconds include "NxTimeDrop" and "NxTimeFiber". "NxTodo" is in the shaddow of "NxTimeFiber"
            .map{|item| BankEstimations::itemsEstimationInSeconds(item) }
            .inject(0, :+)
        totalInSeconds = fibersAndDropsTimeInSeconds + timeMiscInSeconds

        timeparameters = [
            "> time commitment pending : #{(fibersAndDropsTimeInSeconds.to_f/3600).round(2)} hours, light speed: #{TheSpeedOfLight::getDaySpeedOfLight().to_s.green}",
            "> time estimation (others): #{(timeMiscInSeconds.to_f/3600).round(2)} hours",
            "> projected end           : #{Time.at( Time.new.to_i + totalInSeconds ).to_s}",
        ]

        system("clear")
        store = ItemStore.new()
        vspaceleft = CommonUtils::screenHeight() - 4

        puts ""
        vspaceleft = vspaceleft - 1

        # The99 Percent
        line = The99Percent::line()
        puts line
        vspaceleft = vspaceleft - 1

        puts timeparameters.join("\n")
        vspaceleft = vspaceleft - timeparameters.size

        # TimeCommitment report
        timecommitments = NxTimeFibers::itemsForListing()
        if timecommitments.size > 0 then
            puts ""
            puts "time commitments".green
            vspaceleft = vspaceleft - 1
            timecommitments.each{|item|
                store.register(item, false)
                line = "(#{store.prefixString()}) #{NxTimeFibers::toStringWithDetails(item, true)}"
                nxball = NxBalls::getNxBallForItemOrNull(item)
                if nxball then
                    line = "#{line} #{NxBalls::toRunningStatement(nxball)}".green
                end
                puts line
                vspaceleft = vspaceleft - 1
            }
        end

        nxballs = NxBalls::items()
                    .select{|nxball| !CatalystListing::nxballHasAnItemInThere(nxball, timecommitments + listingItems) }

        if nxballs.size > 0 then
            puts ""
            vspaceleft = vspaceleft - 1
            nxballs
                .each{|nxball|
                    store.register(nxball, false)
                    puts "(#{store.prefixString()}) #{NxBalls::toString(nxball)}".green
                    vspaceleft = vspaceleft - 1
                }
        end

        puts ""
        input = LucilleCore::askQuestionAnswerAsString("> ")
        return if input == ""
        CatalystListing::listingCommandInterpreter(input, store)
    end

    # CatalystListing::doDisplayListing2Pure(listingItems, totalInSeconds)
    def self.doDisplayListing2Pure(listingItems, totalInSeconds)

        system("clear")
        store = ItemStore.new()
        vspaceleft = CommonUtils::screenHeight() - 5

        puts ""
        puts "> strat | lock | top | ondate | timedrop | fiber/todo | wave | block".yellow
        puts "#{" " * (CommonUtils::screenWidth()-65)}light speed: #{TheSpeedOfLight::getDaySpeedOfLight().round(3).to_s.green}, projected end: #{Time.at( Time.new.to_i + totalInSeconds ).to_s}"
        vspaceleft = vspaceleft - 1

        strats = TxStratospheres::listingItems()
        if strats.size > 0 then
            strats.each{|item|
                linecount = CatalystListing::printItem(store, item, !Skips::isSkipped(item["uuid"]), "")
                vspaceleft = vspaceleft - linecount
            }
        end

        tops = NxTops::listingItems()

        nxballs = NxBalls::items()
                    .select{|nxball| !CatalystListing::nxballHasAnItemInThere(nxball, listingItems + tops) }

        if nxballs.size > 0 then
            nxballs
                .each{|nxball|
                    store.register(nxball, false)
                    puts "(#{store.prefixString()}) #{NxBalls::toString(nxball)}".green
                    vspaceleft = vspaceleft - 1
                }
        end

        tops = NxTops::listingItems()
        if tops.size > 0 then
            tops.each{|item|
                store.register(item, !Skips::isSkipped(item["uuid"]))
                line = "(#{store.prefixString()}) #{NxTops::toString(item)}"
                nxball = NxBalls::getNxBallForItemOrNull(item)
                if nxball then
                    line = "#{line} #{NxBalls::toRunningStatement(nxball)}".green
                end
                puts line
                vspaceleft = vspaceleft - 1
            }
        end

        items1, items2 = listingItems.partition{|item| NxBalls::getNxBallForItemOrNull(item) }
        (items1 + items2)
            .each{|item|
                next if Locks::isLocked(item["uuid"])
                linecount = CatalystListing::printItem(store, item, !Skips::isSkipped(item["uuid"]), "")
                vspaceleft = vspaceleft - linecount
                break if vspaceleft <= 0
            }

        puts ""
        input = LucilleCore::askQuestionAnswerAsString("> ")
        return if input == ""
        return "exit" if input == "exit"

        CatalystListing::listingCommandInterpreter(input, store)
    end

    # CatalystListing::mainProgram2Pure()
    def self.mainProgram2Pure()

        initialCodeTrace = CommonUtils::stargateTraceCode()

        $SyncConflictInterruptionFilepath = nil

        loop {

            if CommonUtils::stargateTraceCode() != initialCodeTrace then
                puts "Code change detected"
                break
            end

            if $SyncConflictInterruptionFilepath then
                puts "$SyncConflictInterruptionFilepath: #{$SyncConflictInterruptionFilepath}"
                exit
            end

            LucilleCore::locationsAtFolder("#{ENV['HOME']}/Galaxy/DataHub/NxTodos-BufferIn")
                .each{|location|
                    next if File.basename(location).start_with?(".")
                    item = NxTriages::bufferInImport(location)
                    puts "Picked up from NxTodos-BufferIn: #{JSON.pretty_generate(item)}"
                    LucilleCore::removeFileSystemLocation(location)
                }

            listingItems = CatalystListing::listingItems()

            fibersAndDropsTimeInSeconds = CatalystListing::fibersAndDropsTimePendingInSeconds()
            timeMiscInSeconds = listingItems
                .select{|item| ["NxTimeDrop", "NxTimeFiber", "NxTodo"].include?(item["mikuType"]) } # fibersAndDropsTimeInSeconds include "NxTimeDrop" and "NxTimeFiber". "NxTodo" is in the shaddow of "NxTimeFiber"
                .map{|item| BankEstimations::itemsEstimationInSeconds(item)}
                .inject(0, :+)
            totalInSeconds = fibersAndDropsTimeInSeconds + timeMiscInSeconds

            TheSpeedOfLight::performAdjustements(totalInSeconds)

            CatalystListing::doDisplayListing2Pure(listingItems, totalInSeconds)
        }
    end
end
