# encoding: UTF-8

class CatalystUI

    # CatalystUI::applyNextTransformationToFile(filepath)
    def self.applyNextTransformationToFile(filepath)
        content = IO.read(filepath).strip
        content = SectionsType0141::applyNextTransformationToContent(content)
        File.open(filepath, "w"){|f| f.puts(content) }
    end

    # CatalystUI::accessProjects()
    def self.accessProjects()

        loop {
            system("clear")

            menuitems = LCoreMenuItemsNX1.new()

            puts ""

            Asteroids::asteroids()
                .select{|asteroid|
                    asteroid["orbital"]["type"] == "repeating-daily-time-commitment-8123956c-05"
                }
                .sort{|a1, a2| a1["unixtime"] <=> a2["unixtime"] }
                .each{|asteroid|
                    menuitems.item(
                        Asteroids::toString(asteroid),
                        lambda { Asteroids::landing(asteroid) }
                    )
                }

            puts ""

            Calendar::dates().each{|date|
                menuitems.item(
                    "[calendar] #{date}",
                    lambda { 
                        filepath = Calendar::dateToFilepath(date)
                        system("open '#{filepath}'")
                    }
                )
            }

            puts ""

            Asteroids::asteroids()
                .select{|asteroid|
                    asteroid["orbital"]["type"] == "open-project-in-the-background-b458aa91-6e1"
                }
                .sort{|a1, a2| a1["unixtime"] <=> a2["unixtime"] }
                .each{|asteroid|
                    menuitems.item(
                        Asteroids::toString(asteroid),
                        lambda { Asteroids::landing(asteroid) }
                    )
                }

            puts ""

            status = menuitems.promptAndRunSandbox()
            break if !status
        }
    end

    # CatalystUI::standardDisplay(catalystObjects)
    def self.standardDisplay(catalystObjects)

        system("clear")

        verticalSpaceLeft = Miscellaneous::screenHeight()-4
        menuitems = LCoreMenuItemsNX1.new()

        puts ""

        filepath = "#{Miscellaneous::catalystDataCenterFolderpath()}/Interface-Top.txt"
        text = IO.read(filepath).strip
        if text.size > 0 then
            text = text.lines.first(10).join().strip.lines.map{|line| "    #{line}" }.join()
            puts ""
            puts File.basename(filepath)
            puts text
            verticalSpaceLeft = verticalSpaceLeft - (DisplayUtils::verticalSize(text) + 2)
        end

        dates =  Calendar::dates()
                    .select {|date| date <= Time.new.to_s[0, 10] }
        if dates.size > 0 then
            puts ""
            verticalSpaceLeft = verticalSpaceLeft - 1
            dates
                .each{|date|
                    next if date > Time.new.to_s[0, 10]
                    puts "🗓️  "+date
                    verticalSpaceLeft = verticalSpaceLeft - 1
                    str = IO.read(Calendar::dateToFilepath(date))
                        .strip
                        .lines
                        .map{|line| "    #{line}" }
                        .join()
                    puts str
                    verticalSpaceLeft = verticalSpaceLeft - DisplayUtils::verticalSize(str)
                }
        end

        catalystObjects
            .each{|object|
                str = DisplayUtils::makeDisplayStringForCatalystListing(object)
                break if (verticalSpaceLeft - DisplayUtils::verticalSize(str) < 0)
                verticalSpaceLeft = verticalSpaceLeft - DisplayUtils::verticalSize(str)
                menuitems.item(
                    str,
                    lambda { object["execute"].call("ec23a3a3-bfa0-45db-a162-fdd92da87f64") }
                )
            }

        # --------------------------------------------------------------------------
        # Prompt

        puts ""
        print "--> "
        command = STDIN.gets().strip

        if command == "" then
            return
        end

        if Miscellaneous::isInteger(command) then
            position = command.to_i
            menuitems.executeFunctionAtPositionGetValueOrNull(position)
            return
        end

        if command == ".." then
            object = catalystObjects.first
            return if object.nil?
            object["execute"].call("c2c799b1-bcb9-4963-98d5-494a5a76e2e6")
            return
        end

        if command == 'expose' then
            object = catalystObjects.first
            return if object.nil?
            puts JSON.pretty_generate(object)
            LucilleCore::pressEnterToContinue()
            return
        end

        if command == "++" then
            object = catalystObjects.first
            return if object.nil?
            unixtime = Miscellaneous::codeToUnixtimeOrNull("+1 hours")
            puts "Pushing to #{Time.at(unixtime).to_s}"
            DoNotShowUntil::setUnixtime(object["uuid"], unixtime)
            return
        end

        if command.start_with?('+') and (unixtime = Miscellaneous::codeToUnixtimeOrNull(command)) then
            object = catalystObjects.first
            return if object.nil?
            puts "Pushing to #{Time.at(unixtime).to_s}"
            DoNotShowUntil::setUnixtime(object["uuid"], unixtime)
            return
        end

        if command == "::" then
            filepath = "#{Miscellaneous::catalystDataCenterFolderpath()}/Interface-Top.txt"
            system("open '#{filepath}'")
            return
        end

        if command == "[]" then
            filepath = "#{Miscellaneous::catalystDataCenterFolderpath()}/Interface-Top.txt"
            CatalystUI::applyNextTransformationToFile(filepath)
            return
        end

        if command == "l+" then
            ms = LCoreMenuItemsNX1.new()
            ms.item(
                "asteroid (line)",
                lambda { Asteroids::issuePlainAsteroidInteractivelyOrNull() }
            )
            ms.item(
                "asteroid (general)",
                lambda { Asteroids::issueDatapointAndAsteroidInteractivelyOrNull() }
            )
            ms.item(
                "wave",
                lambda { Waves::issueNewWaveInteractivelyOrNull() }
            )
            ms.promptAndRunSandbox()
            return
        end

        if command == "/" then
            DataPortalUI::dataPortalFront()
            return
        end

        if command == ";" then
            CatalystUI::accessProjects()
            return
        end
    end

    @@haveStartedThreads = false

    # CatalystUI::startThreadsIfNotStarted()
    def self.startThreadsIfNotStarted()

        return if @@haveStartedThreads

        puts "-> starting Threads"

        Thread.new {
            loop {
                sleep 10
                CatalystObjectsOperator::getCatalystListingObjectsOrdered()
                    .select{|object| object["isRunningForLong"] }
                    .first(1)
                    .each{|object|
                        Miscellaneous::onScreenNotification("Catalyst Interface", "An object is running for long")
                    }
                sleep 120
            }
        }

        Thread.new {
            loop {
                sleep 20
                if ProgrammableBooleans::trueNoMoreOftenThanEveryNSeconds("f5f52127-c140-4c59-85a2-8242b546fe1f", 3600) then
                    system("#{File.dirname(__FILE__)}/../vienna-import")
                end
                sleep 3600
            }
        }

        Thread.new {
            loop {
                sleep 30
                # We run the full sequence once a day (first opportunity after midnight)
                next if KeyValueStore::flagIsTrue(nil, "9311f726-6083-475d-a8f6-0f7dcc9b993d:#{Miscellaneous::today()}")
                GlobalMaintenance::main(false)
                KeyValueStore::setFlagTrue(nil, "9311f726-6083-475d-a8f6-0f7dcc9b993d:#{Miscellaneous::today()}")
                sleep 60
            }
        }

        @@haveStartedThreads = true
    end

    # CatalystUI::standardUILoop()
    def self.standardUILoop()

        haveStartedThreads = false

        loop {

            # Some Admin
            Miscellaneous::importFromLucilleInbox()

            # Displays
            objects = CatalystObjectsOperator::getCatalystListingObjectsOrdered()
            if objects.empty? then
                puts "No catalyst object found"
                LucilleCore::pressEnterToContinue()
                return
            end
            CatalystUI::standardDisplay(objects)

            CatalystUI::startThreadsIfNotStarted()
        }
    end
end


