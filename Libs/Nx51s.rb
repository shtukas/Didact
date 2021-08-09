# encoding: UTF-8

=begin
{
    "type"       : "until-done" | "timespan"
    "parameters" : 
}
{
    "type"       : "until-done"
    "parameters" : nil
}
{
    "type"       : "timespan"
    "parameters" : Float # daily commitment in hours 
}
=end

class Nx51RunDirectives

    # Nx51RunDirectives::getDirectiveOrNull(uuid)
    def self.getDirectiveOrNull(uuid)
        directive =  KeyValueStore::getOrNull(nil, "8e54d4fc-a675-44a8-af1a-b0c49d7508e8:#{uuid}")
        return nil if directive.nil?
        JSON.parse(directive)
    end

    # Nx51RunDirectives::directiveToString(directive)
    def self.directiveToString(directive)
        if directive["type"] == "until-done" then
            return "(completed)"
        end
        if directive["type"] == "timespan" then
            return "(span: #{directive["parameters"]})"
        end
    end

    # Nx51RunDirectives::directiveToStringOrEmpty(uuid)
    def self.directiveToStringOrEmpty(uuid)
        directive = Nx51RunDirectives::getDirectiveOrNull(uuid)
        return "" if directive.nil?
        " #{Nx51RunDirectives::directiveToString(directive)}"
    end

    # Nx51RunDirectives::setDirective(uuid, directive)
    def self.setDirective(uuid, directive)
        KeyValueStore::set(nil, "8e54d4fc-a675-44a8-af1a-b0c49d7508e8:#{uuid}", JSON.generate(directive))
    end

    # Nx51RunDirectives::interactivelyBuildDirectiveOrNull()
    def self.interactivelyBuildDirectiveOrNull()
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["until-done", "timespan"])
        return nil if type.nil?
        if type == "until-done" then
            return {
                "type"       => "until-done",
                "parameters" => nil
            }
        end
        if type == "timespan" then
            return {
                "type"       => "timespan",
                "parameters" => LucilleCore::askQuestionAnswerAsString("timespan in hours: ").to_f
            }
        end
    end
end

class Nx51s

    # Nx51s::databaseItemToNx51(item)
    def self.databaseItemToNx51(item)
        item["contentType"]    = item["payload1"]
        item["contentPayload"] = item["payload2"]
        item["ordinal"]        = item["payload3"].to_f # 😬
        item
    end

    # Nx51s::nx51s()
    def self.nx51s()
        CatalystDatabase::getItemsByCatalystType("Nx51").map{|item|
            Nx51s::databaseItemToNx51(item)
        }
    end

    # Nx51s::nx51sPerOrdinal()
    def self.nx51sPerOrdinal()
        Nx51s::nx51s()
            .sort{|n1, n2| n1["ordinal"]<=>n2["ordinal"] }
    end

    # Nx51s::commitNx51ToDisk(nx51)
    def self.commitNx51ToDisk(nx51)
        uuid         = nx51["uuid"]
        unixtime     = nx51["unixtime"]
        description  = nx51["description"]
        catalystType = "Nx51"
        payload1     = nx51["contentType"]
        payload2     = nx51["contentPayload"]
        payload3     = nx51["ordinal"]
        payload4     = nil 
        payload5     = nil
        CatalystDatabase::insertItem(uuid, unixtime, description, catalystType, payload1, payload2, payload3, payload4, payload5)
    end

    # Nx51s::getNx51ByUUIDOrNull(uuid)
    def self.getNx51ByUUIDOrNull(uuid)
        item = CatalystDatabase::getItemByUUIDOrNull(uuid)
        return nil if item.nil?
        Nx51s::databaseItemToNx51(item)
    end

    # Nx51s::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        uuid = SecureRandom.uuid

        unixtime     = Time.new.to_f

        description = LucilleCore::askQuestionAnswerAsString("description (empty for abort): ")
        if description == "" then
            return nil
        end

        coordinates  = Axion::interactivelyIssueNewCoordinatesOrNull()

        ordinal      = Nx51s::decideOrdinal(description)

        catalystType = "Nx51"
        payload1     = coordinates ? coordinates["contentType"] : nil
        payload2     = coordinates ? coordinates["contentPayload"] : nil
        payload3     = ordinal
        CatalystDatabase::insertItem(uuid, unixtime, description, catalystType, payload1, payload2, payload3, nil, nil)

        Nx51s::getNx51ByUUIDOrNull(uuid)
    end

    # Nx51s::minusOneUnixtime()
    def self.minusOneUnixtime()
        items = Nx51s::nx51s()
        return Time.new.to_i if items.empty?
        items.map{|item| item["unixtime"] }.min - 1
    end

    # Nx51s::interactivelyDetermineNewItemOrdinal()
    def self.interactivelyDetermineNewItemOrdinal()
        system('clear')
        items = Nx51s::nx51s()
        return 1 if items.empty?
        items.each{|item|
            puts "- #{Nx51s::toString(item)}"
        }
        LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
    end

    # Nx51s::issueNx51UsingInboxLineInteractive(line)
    def self.issueNx51UsingInboxLineInteractive(line)
        uuid         = SecureRandom.uuid
        unixtime     = Time.new.to_f
        description  = line
        catalystType = "Nx51"
        payload1     = nil
        payload2     = nil
        payload3     = Nx51s::decideOrdinal(description)
        CatalystDatabase::insertItem(uuid, unixtime, description, catalystType, payload1, payload2, payload3, nil, nil)
        Nx51s::getNx51ByUUIDOrNull(uuid)
    end

    # --------------------------------------------------
    # Operations

    # Nx51s::toString(nx51)
    def self.toString(nx51)
        uuid = nx51["uuid"]
        contentType = nx51["contentType"]
        str1 = (contentType and contentType.size > 0) ? " (#{nx51["contentType"]})" : ""
        "[nx51] (ord: #{"%6.3f" % nx51["ordinal"]})#{Nx51RunDirectives::directiveToStringOrEmpty(uuid).green} #{nx51["description"]}#{str1}"
    end

    # Nx51s::complete(nx51)
    def self.complete(nx51)
        File.open("/Users/pascal/Galaxy/DataBank/Catalyst/Nx51s-Completion-Log.txt", "a"){|f| f.puts("#{Time.new.to_s}|#{Time.new.to_i}|#{Nx51s::toString(nx51)}") }
        Axion::postAccessCleanUp(nx51["contentType"], nx51["contentPayload"])
        CatalystDatabase::delete(nx51["uuid"])
    end

    # Nx51s::getNextOrdinal()
    def self.getNextOrdinal()
        (([1]+Nx51s::nx51s().map{|nx51| nx51["ordinal"] }).max + 1).floor
    end

    # Nx51s::decideOrdinal(description)
    def self.decideOrdinal(description)
        system("clear")
        puts ""
        puts description.green
        puts ""
        Nx51s::nx51s()
            .sort{|n1, n2| n1["ordinal"] <=> n2["ordinal"] }
            .each{|nx51|
                puts "(#{"%7.3f" % nx51["ordinal"]}) #{Nx51s::toString(nx51)}"
            }
        puts ""
        ordinal = LucilleCore::askQuestionAnswerAsString("ordinal (empty for last position): ")
        if ordinal == "" then
            Nx51s::getNextOrdinal()
        else
            ordinal.to_f
        end
    end

    # Nx51s::selectOneNx51OrNull()
    def self.selectOneNx51OrNull()
        nx51s = Nx51s::nx51sPerOrdinal()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("Nx51", nx51s, lambda{|nx51| "(#{"%7.3f" % nx51["ordinal"]}) #{Nx51s::toString(nx51)}" })
    end

    # Nx51s::access(nx51)
    def self.access(nx51)
        uuid = nx51["uuid"]

        nxball = NxBalls::makeNxBall([uuid, Work::bankaccount()])

        thr = Thread.new {
            loop {
                sleep 60

                if (Time.new.to_i - nxball["cursorUnixtime"]) >= 600 then
                    nxball = NxBalls::upgradeNxBall(nxball, false)
                end

                if (Time.new.to_i - nxball["startUnixtime"]) >= 3600 then
                    Utils::onScreenNotification("Catalyst", "Nx51 item running for more than an hour")
                end
            }
        }

        system("clear")

        loop {

            nx51 = Nx51s::getNx51ByUUIDOrNull(uuid)

            return if nx51.nil?

            system("clear")

            rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)

            puts "running: (#{"%.3f" % rt}) #{Nx51s::toString(nx51)} (#{BankExtended::runningTimeString(nxball)})".green

            puts "note:\n#{StructuredTodoTexts::getNoteOrNull(uuid)}".green

            puts ""

            puts "uuid: #{uuid}".yellow
            puts "coordinates: #{nx51["contentType"]}, #{nx51["contentPayload"]}".yellow
            puts "DoNotDisplayUntil: #{DoNotShowUntil::getDateTimeOrNull(nx51["uuid"])}".yellow

            puts ""

            puts "[item   ] access | note | [] | <datecode> | detach running | pause | pursue | exit | completed | update description | update contents | update ordinal | destroy".yellow

            puts UIServices::mainMenuCommands().yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == "exit"

            if command == "++" then
                DoNotShowUntil::setUnixtime(uuid, Time.new.to_i+3600)
                break
            end

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(uuid, unixtime)
                break
            end

            if Interpreting::match("note", command) then
                note = Utils::editTextSynchronously(StructuredTodoTexts::getNoteOrNull(nx51["uuid"]) || "")
                StructuredTodoTexts::setNote(uuid, note)
                next
            end

            if command == "[]" then
                StructuredTodoTexts::applyT(uuid)
                next
            end

            if Interpreting::match("access", command) then
                update = nil
                Axion::access(nx51["contentType"], nx51["contentPayload"], update)
                next
            end

            if Interpreting::match("pause", command) then
                NxBalls::closeNxBall(nxball, true)
                puts "Starting pause at #{Time.new.to_s}"
                LucilleCore::pressEnterToContinue()
                nxball = NxBalls::makeNxBall([uuid, Work::bankaccount()])
                next
            end

            if command == "pursue" then
                # We close the ball and issue a new one
                NxBalls::closeNxBall(nxball, true)
                nxball = NxBalls::makeNxBall([uuid, Work::bankaccount()])
                next
            end

            if Interpreting::match("detach running", command) then
                DetachedRunning::issueNew2(Nx51s::toString(nx51), Time.new.to_i, [uuid, Work::bankaccount()])
                break
            end

            if Interpreting::match("completed", command) then
                Nx51s::complete(nx51)
                break
            end

            if Interpreting::match("update description", command) then
                description = Utils::editTextSynchronously(nx51["description"])
                if description.size > 0 then
                    CatalystDatabase::updateDescription(nx51["uuid"], description)
                end
                next
            end

            if Interpreting::match("update contents", command) then
                update = nil
                Axion::edit(nx51["contentType"], nx51["contentPayload"], update)
                next
            end

            if Interpreting::match("update ordinal", command) then
                ordinal = Nx51s::decideOrdinal(Nx51s::toString(nx51))
                nx51["ordinal"] = ordinal
                Nx51s::commitNx51ToDisk(nx51)
                break
            end

            if Interpreting::match("destroy", command) then
                Nx51s::complete(nx51)
                break
            end

            UIServices::mainMenuInterpreter(command)
        }

        thr.exit

        NxBalls::closeNxBall(nxball, true)

        Axion::postAccessCleanUp(nx51["contentType"], nx51["contentPayload"])
    end

    # --------------------------------------------------
    # nx16s

    # Nx51s::ns16OrNull(nx51)
    def self.ns16OrNull(nx51)
        uuid = nx51["uuid"]
        directive = Nx51RunDirectives::getDirectiveOrNull(uuid)
        rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)
        if directive and (directive["type"] == "timespan") and (rt > directive["parameters"]) then
            return nil
        end
        announce = "(#{"%4.2f" % rt}) #{Nx51s::toString(nx51)}".gsub("(0.00)", "      ")
        {
            "uuid"     => uuid,
            "announce" => announce,
            "access"   => lambda{ Nx51s::access(nx51) },
            "done"     => lambda{
                if LucilleCore::askQuestionAnswerAsBoolean("done '#{Nx51s::toString(nx51)}' ? ", true) then
                    Nx51s::complete(nx51)
                end
            },
            "[]"      => lambda { StructuredTodoTexts::applyT(uuid) },
            "rt"      => rt
        }
    end

    # Nx51s::ns16s()
    def self.ns16s()
        Nx51s::nx51sPerOrdinal()
            .map{|nx51| Nx51s::ns16OrNull(nx51) }
            .compact
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
    end

    # --------------------------------------------------

    # Nx51s::nx19s()
    def self.nx19s()
        Nx51s::nx51s().map{|item|
            {
                "announce" => Nx51s::toString(item),
                "lambda"   => lambda { Nx51s::access(item) }
            }
        }
    end

    # Nx51s::operations()
    def self.operations()
        loop {
            puts "Nx51 Ops: dive | (select item and) update ordinal".yellow
            print "> (empty to exit) "
            command = STDIN.gets().strip
            break if command == ""
            if command == "dive" then
                nx51 = Nx51s::selectOneNx51OrNull()
                next if nx51.nil?
                Nx51s::access(nx51)
            end
            if command == "update ordinal" then
                nx51 = Nx51s::selectOneNx51OrNull()
                next if nx51.nil?
                ordinal = LucilleCore::askQuestionAnswerAsString("ordinal (empty for last position): ")
                if ordinal != "" then
                    ordinal = ordinal.to_f
                else
                    ordinal = Nx51s::getNextOrdinal()
                end
                nx51["ordinal"] = ordinal
                Nx51s::commitNx51ToDisk(nx51)
            end
        }
    end

    # Nx51s::workMenuCommands()
    def self.workMenuCommands()
        "[work   ] set directives | set ordinals"
    end

    # Nx51s::workMenuInterpreter(command)
    def self.workMenuInterpreter(command)
        if Interpreting::match("set directives", command) then
            loop {
                nx51 = LucilleCore::selectEntityFromListOfEntitiesOrNull("nx51", Nx51s::nx51sPerOrdinal(), lambda{|nx51| Nx51s::toString(nx51) })
                break if nx51.nil?
                directive = Nx51RunDirectives::interactivelyBuildDirectiveOrNull()
                next if directive.nil?
                Nx51RunDirectives::setDirective(nx51["uuid"], directive)
            }
            return
        end
        if Interpreting::match("set ordinals", command) then
            loop {
                nx51 = LucilleCore::selectEntityFromListOfEntitiesOrNull("nx51", Nx51s::nx51sPerOrdinal(), lambda{|nx51| Nx51s::toString(nx51) })
                break if nx51.nil?
                ordinal = LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
                nx51["ordinal"] = ordinal
                Nx51s::commitNx51ToDisk(nx51)
            }
            return
        end
    end

end
