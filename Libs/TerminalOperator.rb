# encoding: UTF-8

# ------------------------------------------------------------------------------------------

class ItemStore
    def initialize() # : Integer
        @items = []
        @defaultItem = nil
    end
    def itemShouldBeDefault(item)
        uuid = item["uuid"]
        return false if KeyValueStore::flagIsTrue(nil, "6413c62b-d0d3-4fdc-a9d1-d00adae3a1ee:#{Utils::today()}:#{uuid}")
        @defaultItem.nil?
    end
    def register(item)
        cursor = @items.size
        @items << item
        if itemShouldBeDefault(item) then
            @defaultItem = item
        end
    end
    def latestEnteredItemIsDefault()
        return false if @defaultItem.nil?
        @items.last["uuid"] == @defaultItem["uuid"]
    end
    def prefixString()
        indx = @items.size-1
        latestEnteredItemIsDefault() ? "(-->)".green : "(#{"%3d" % indx})"
    end
    def get(indx)
        @items[indx].clone
    end
    def getDefault()
        @defaultItem.clone
    end
end

class ItemStoreOps

    # ItemStoreOps::delistForDefault(uuid)
    def self.delistForDefault(uuid)
        KeyValueStore::setFlagTrue(nil, "6413c62b-d0d3-4fdc-a9d1-d00adae3a1ee:#{Utils::today()}:#{uuid}")
    end
end

class NS16sOperator

    # NS16sOperator::getFocusUnixtimeSortingTime(uuid)
    def self.getFocusUnixtimeSortingTime(uuid)
        unixtime = KeyValueStore::getOrNull(nil, "d5c340ae-c9f1-4dfb-961b-71b4d152e271:#{uuid}")
        return unixtime.to_f if unixtime
        unixtime = Time.new.to_f
        KeyValueStore::set(nil, "d5c340ae-c9f1-4dfb-961b-71b4d152e271:#{uuid}", unixtime)
        unixtime
    end

    # NS16sOperator::focus()
    def self.focus()
        [
            Mx49s::ns16s(),
            Nx70s::ns16s(),
            CatalystTxt::catalystTxtNs16s()
        ]
            .flatten
            .compact
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|ns16| InternetStatus::ns16ShouldShow(ns16["uuid"]) }
            .sort{|i1, i2| NS16sOperator::getFocusUnixtimeSortingTime(i1["uuid"]) <=> NS16sOperator::getFocusUnixtimeSortingTime(i2["uuid"]) }
    end

    # NS16sOperator::ns16s()
    def self.ns16s()

        LucilleCore::locationsAtFolder("/Users/pascal/Desktop/Nx50s (Random)")
            .map{|location|
                puts "Importing Nx50s (Random): #{location}"
                nx50 = {
                    "uuid"        => SecureRandom.uuid,
                    "unixtime"    => Time.new.to_i,
                    "ordinal"     => Nx50s::ordinalBetweenN1thAndN2th(30, 50),
                    "description" => File.basename(location),
                    "atom"        => CoreData5::issueAionPointAtomUsingLocation(location),
                }
                Nx50s::commit(nx50)
                LucilleCore::removeFileSystemLocation(location)
            }

        [
            Anniversaries::ns16s(),
            Calendar::ns16s(),
            JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Binaries/amanda-bins`),
            JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Binaries/fitness ns16s`),
            Inbox::ns16s(),
            TwentyTwo::ns16s()
        ]
            .flatten
            .compact
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|ns16| InternetStatus::ns16ShouldShow(ns16["uuid"]) }
    end
end

class TerminalDisplayOperator

    # TerminalDisplayOperator::display(floats, waves, spaceships, focus, ns16s)
    def self.display(floats, waves, spaceships, focus, ns16s)

        commandStrWithPrefix = lambda{|ns16, isDefaultItem|
            return "" if !isDefaultItem
            return "" if ns16["commands"].nil?
            return "" if ns16["commands"].empty?
            " (commands: #{ns16["commands"].join(", ")})".yellow
        }

        system("clear")

        vspaceleft = Utils::screenHeight()-4

        puts ""
        puts "#{TwentyTwo::dx()} (Nx50: #{Nx50s::nx50s().size} items)"
        vspaceleft = vspaceleft - 2

        puts ""

        store = ItemStore.new()

        if !InternetStatus::internetIsActive() then
            puts "INTERNET IS OFF".green
            vspaceleft = vspaceleft - 1
        end

        floats.each{|ns16|
            store.register(ns16)
            line = "#{store.prefixString()} [#{Time.at(ns16["Mx48"]["unixtime"]).to_s[0, 10]}] #{ns16["announce"]}".yellow
            break if (!store.latestEnteredItemIsDefault() and store.getDefault() and ((vspaceleft - Utils::verticalSize(line)) < 0))
            puts line
            vspaceleft = vspaceleft - Utils::verticalSize(line)
        }
        if floats.size>0 then
            puts ""
            vspaceleft = vspaceleft - 1
        end

        waves.each{|ns16|
            store.register(ns16)
            line = "#{store.prefixString()} #{ns16["announce"]}#{commandStrWithPrefix.call(ns16, store.latestEnteredItemIsDefault())}"
            break if (!store.latestEnteredItemIsDefault() and store.getDefault() and ((vspaceleft - Utils::verticalSize(line)) < 0))
            puts line
            vspaceleft = vspaceleft - Utils::verticalSize(line)
        }
        if waves.size>0 then
            puts ""
            vspaceleft = vspaceleft - 1
        end

        focus.each{|ns16|
            store.register(ns16)
            line = "#{store.prefixString()} #{ns16["announce"]}#{commandStrWithPrefix.call(ns16, store.latestEnteredItemIsDefault())}"
            break if (!store.latestEnteredItemIsDefault() and store.getDefault() and ((vspaceleft - Utils::verticalSize(line)) < 0))
            puts line
            vspaceleft = vspaceleft - Utils::verticalSize(line)
        }
        if focus.size>0 then
            puts ""
            vspaceleft = vspaceleft - 1
        end

        spaceships.each{|ns16|
            store.register(ns16)
            line = "#{store.prefixString()} #{ns16["announce"]}#{commandStrWithPrefix.call(ns16, store.latestEnteredItemIsDefault())}"
            break if (!store.latestEnteredItemIsDefault() and store.getDefault() and ((vspaceleft - Utils::verticalSize(line)) < 0))
            puts line
            vspaceleft = vspaceleft - Utils::verticalSize(line)
        }
        if spaceships.size>0 then
            puts ""
            vspaceleft = vspaceleft - 1
        end

        running = BTreeSets::values(nil, "a69583a5-8a13-46d9-a965-86f95feb6f68")
        running
                .sort{|t1, t2| t1["unixtime"] <=> t2["unixtime"] } # || 0 because we had some running while updating this
                .each{|nxball|
                    delegate = {
                        "uuid"  => nxball["uuid"],
                        "NS198" => "NxBallDelegate1" 
                    }
                    store.register(delegate)
                    line = "(#{store.prefixString()}) #{nxball["description"]} (#{NxBallsService::runningStringOrEmptyString("", nxball["uuid"], "")})".green
                    puts line
                    vspaceleft = vspaceleft - Utils::verticalSize(line)
                }
        if running.size>0 then
            puts ""
            vspaceleft = vspaceleft - 1
        end

        ns16s
            .each{|ns16|
                store.register(ns16)
                line = ns16["announce"]
                if store.latestEnteredItemIsDefault() then
                    line = line.yellow
                end
                line = "#{store.prefixString()} #{line}#{commandStrWithPrefix.call(ns16, store.latestEnteredItemIsDefault())}"
                break if (!store.latestEnteredItemIsDefault() and store.getDefault() and ((vspaceleft - Utils::verticalSize(line)) < 0))
                puts line
                vspaceleft = vspaceleft - Utils::verticalSize(line)
            }

        puts ""

        command = LucilleCore::askQuestionAnswerAsString("> ")

        return if command == ""

        if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
            if (item = store.getDefault()) then
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
                return
            end
        end

        if (i = Interpreting::readAsIntegerOrNull(command)) then
            item = store.get(i)
            return if item.nil?
            CommandsOps::operator1(item, "..")
            return
        end

        if command == "expose" and (item = store.getDefault()) then
            puts JSON.pretty_generate(item)
            LucilleCore::pressEnterToContinue()
            return
        end

        CommandsOps::operator4(command)
        CommandsOps::operator1(store.getDefault(), command)
    end

    # TerminalDisplayOperator::displayLoop()
    def self.displayLoop()
        initialCodeTrace = Utils::codeTrace()
        loop {
            if Utils::codeTrace() != initialCodeTrace then
                puts "Code change detected"
                break
            end
            floats = Mx48s::ns16s()
            waves = Waves::ns16s()
            spaceships = Nx60s::ns16s()
            focus = NS16sOperator::focus()
            ns16s = NS16sOperator::ns16s()
            TerminalDisplayOperator::display(floats, waves, spaceships, focus, ns16s)
        }
    end
end
