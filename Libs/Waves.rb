
# encoding: UTF-8

class Waves

    # Waves::makeScheduleParametersInteractivelyOrNull() # [type, value]
    def self.makeScheduleParametersInteractivelyOrNull()

        scheduleTypes = ['sticky', 'repeat']
        scheduleType = LucilleCore::selectEntityFromListOfEntitiesOrNull("schedule type: ", scheduleTypes)

        return nil if scheduleType.nil?

        if scheduleType=='sticky' then
            fromHour = LucilleCore::askQuestionAnswerAsString("From hour (integer): ").to_i
            return ["sticky", fromHour]
        end

        if scheduleType=='repeat' then

            repeat_types = ['every-n-hours','every-n-days','every-this-day-of-the-week','every-this-day-of-the-month']
            type = LucilleCore::selectEntityFromListOfEntities_EnsureChoice("repeat type: ", repeat_types, lambda{|entity| entity })

            return nil if type.nil?

            if type=='every-n-hours' then
                print "period (in hours): "
                value = STDIN.gets().strip.to_f
                return [type, value]
            end
            if type=='every-n-days' then
                print "period (in days): "
                value = STDIN.gets().strip.to_f
                return [type, value]
            end
            if type=='every-this-day-of-the-month' then
                print "day number (String, length 2): "
                value = STDIN.gets().strip
                return [type, value]
            end
            if type=='every-this-day-of-the-week' then
                weekdays = ['monday','tuesday','wednesday','thursday','friday','saturday','sunday']
                value = LucilleCore::selectEntityFromListOfEntities_EnsureChoice("weekday: ", weekdays, lambda{|entity| entity })
                return [type, value]
            end
        end
        raise "e45c4622-4501-40e1-a44e-2948544df256"
    end

    # Waves::waveToDoNotShowUnixtime(wave)
    def self.waveToDoNotShowUnixtime(wave)
        if wave["repeatType"] == 'sticky' then
            # unixtime1 is the time of the event happening today
            # It can still be ahead of us.
            unixtime1 = (Utils::unixtimeAtComingMidnightAtGivenTimeZone(Utils::getLocalTimeZone()) - 86400) + wave["repeatValue"].to_i*3600
            if unixtime1 > Time.new.to_i then
                return unixtime1
            end
            # We return the event happening tomorrow
            return Utils::unixtimeAtComingMidnightAtGivenTimeZone(Utils::getLocalTimeZone()) + wave["repeatValue"].to_i*3600
        end
        if wave["repeatType"] == 'every-n-hours' then
            return Time.new.to_i+3600 * wave["repeatValue"].to_f
        end
        if wave["repeatType"] == 'every-n-days' then
            return Time.new.to_i+86400 * wave["repeatValue"].to_f
        end
        if wave["repeatType"] == 'every-this-day-of-the-month' then
            cursor = Time.new.to_i + 86400
            while Time.at(cursor).strftime("%d") != wave["repeatValue"] do
                cursor = cursor + 3600
            end
           return cursor
        end
        if wave["repeatType"] == 'every-this-day-of-the-week' then
            mapping = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday']
            cursor = Time.new.to_i + 86400
            while mapping[Time.at(cursor).wday] != wave["repeatValue"] do
                cursor = cursor + 3600
            end
            return cursor
        end
    end

    # Waves::scheduleString(wave)
    def self.scheduleString(wave)
        if wave["repeatType"] == 'sticky' then
            return "sticky, from: #{wave["repeatValue"]}"
        end
        "#{wave["repeatType"]}: #{wave["repeatValue"]}"
    end

    # Waves::interactivelyMakeContentsOrNull() : [type, payload] 
    def self.interactivelyMakeContentsOrNull()
        types = ['line', 'url']
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("types", types)
        return nil if type.nil?
        if type == "line" then
            line  = LucilleCore::askQuestionAnswerAsString("line (empty to abort) : ")
            return nil if line == ""
            return ["Line", line]
        end
        if type == "url" then
            url  = LucilleCore::askQuestionAnswerAsString("url (empty to abort) : ")
            return nil if url == ""
            return ["Url", url]
        end
    end

    # Waves::issueNewWaveInteractivelyOrNull()
    def self.issueNewWaveInteractivelyOrNull()
        wave = {}

        uuid = SecureRandom.uuid

        wave["uuid"] = uuid
        wave["schema"] = "wave"
        wave["unixtime"] = Time.new.to_i

        contents = Waves::interactivelyMakeContentsOrNull()
        return nil if contents.nil?

        if contents[0] == "Line" then
            wave["description"] = contents[1]
            wave["contentType"] = contents[0]
            wave["payload"]     = ""
        end

        if contents[0] == "Url" then
            wave["description"] = contents[1]
            wave["contentType"] = contents[0]
            wave["payload"]     = contents[1]
        end

        schedule = Waves::makeScheduleParametersInteractivelyOrNull()
        if schedule.nil? then
            return nil
        end

        wave["repeatType"] = schedule[0]
        wave["repeatValue"] = schedule[1]

        wave["lastDoneDateTime"] = "#{Time.new.strftime("%Y")}-01-01T00:00:00Z"

        CoreDataTx::commit(wave)

        wave
    end

    # -------------------------------------------------------------------------

    # Waves::storedPriority(wave)
    def self.storedPriority(wave)
        KeyValueStore::getOrNull(nil, "bc068078-45c5-4d54-9a32-8288873b9a55:#{wave["uuid"]}")
    end

    # Waves::getPriorityOrNull(wave)
    def self.getPriorityOrNull(wave)
        value = KeyValueStore::getOrNull(nil, "bc068078-45c5-4d54-9a32-8288873b9a55:#{wave["uuid"]}")
        return value if value
        return "ns:low" if ["every-this-day-of-the-month", "every-this-day-of-the-week"].include?(wave["repeatType"])
        return "ns:low" if ["sticky"].include?(wave["repeatType"])
        nil
    end

    # Waves::setPriority(wave, priority)
    def self.setPriority(wave, priority)
        raise "80910af2-794f-45a4-ad42-d3383894cb42:#{priority}" if !["ns:high", "ns:low"].include?(priority)
        KeyValueStore::set(nil, "bc068078-45c5-4d54-9a32-8288873b9a55:#{wave["uuid"]}", priority)
    end

    # -------------------------------------------------------------------------

    # Waves::toString(wave)
    def self.toString(wave)
        ago = "#{((Time.new.to_i - DateTime.parse(wave["lastDoneDateTime"]).to_time.to_i).to_f/86400).round(2)} days ago"
        "[wave] (#{Waves::scheduleString(wave)}) [#{wave["contentType"].downcase}] #{wave["description"]} (#{ago})"
    end

    # Waves::selectWaveOrNull()
    def self.selectWaveOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("wave", CoreDataTx::getObjectsBySchema("wave").sort{|w1, w2| w1["lastDoneDateTime"] <=> w2["lastDoneDateTime"] }, lambda {|wave| Waves::toString(wave) })
    end

    # Waves::performDone(wave)
    def self.performDone(wave)
        puts "done-ing: #{Waves::toString(wave)}"
        wave["lastDoneDateTime"] = Time.now.utc.iso8601
        CoreDataTx::commit(wave)
        unixtime = Waves::waveToDoNotShowUnixtime(wave)
        DoNotShowUntil::setUnixtime(wave["uuid"], unixtime)
        Bank::put("WAVES-DONE-IMPACT-8F82-BFB47E4541A2", 1)
    end

    # Waves::landing(wave)
    def self.landing(wave)
        loop {

            system("clear")

            return if CoreDataTx::getObjectByIdOrNull(wave["uuid"]).nil?

            uuid = wave["uuid"]

            puts Waves::toString(wave)
            puts "uuid: #{wave["uuid"]}"

            puts "schedule: #{Waves::scheduleString(wave)}"
            puts "last done: #{wave["lastDoneDateTime"]}"
            if DoNotShowUntil::isVisible(wave["uuid"]) then
                puts "active"
            else
                puts "hidden until: #{Time.at(DoNotShowUntil::getUnixtimeOrNull(wave["uuid"])).to_s}"
            end
            puts "priority: #{Waves::storedPriority(wave)}"

            puts "<datecode> | done | update description | recast contents | recast schedule | set low/high priority | destroy | ''".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(uuid, unixtime)
                break
            end

            if Interpreting::match("done", command) then
                Waves::performDone(wave)
            end

            if Interpreting::match("update description", command) then
                wave["description"] = Utils::editTextSynchronously(wave["description"])
                Waves::performDone(wave)
            end

            if Interpreting::match("recast contents", command) then
                contents = Waves::interactivelyMakeContentsOrNull()
                next if contents.nil?
                if contents[0] == "Line" then
                    wave["description"] = contents[1]
                    wave["contentType"] = contents[0]
                    wave["payload"]     = ""
                end
                if contents[0] == "Url" then
                    wave["description"] = contents[1]
                    wave["contentType"] = contents[0]
                    wave["payload"]     = contents[1]
                end
                CoreDataTx::commit(wave)
            end

            if Interpreting::match("recast schedule", command) then
                schedule = Waves::makeScheduleParametersInteractivelyOrNull()
                return if schedule.nil?
                wave["repeatType"] = schedule[0]
                wave["repeatValue"] = schedule[1]
                CoreDataTx::commit(wave)
            end

            if Interpreting::match("set low priority", command) then
                Waves::setPriority(wave, "ns:low")
            end

            if Interpreting::match("set high priority", command) then
               Waves::setPriority(wave, "ns:high")
            end

            if Interpreting::match("destroy", command) then
                if LucilleCore::askQuestionAnswerAsBoolean("Do you want to destroy this item ? : ") then
                    CoreDataTx::delete(wave["uuid"])
                    break
                end
            end

            if Interpreting::match("''", command) then
                UIServices::operationalInterface()
            end
        }
    end

    # Waves::main()
    def self.main()
        loop {
            puts "Waves 🌊 (main)"
            puts "Waves::dailyDoneCountAverage(): #{Waves::dailyDoneCountAverage()}"
            puts "Waves::todayDoneCountRatio()  : #{Waves::todayDoneCountRatio()}"
            options = [
                "new wave",
                "waves dive"
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
            break if option.nil?
            if option == "new wave" then
                Waves::issueNewWaveInteractivelyOrNull()
            end
            if option == "waves dive" then
                loop {
                    system("clear")
                    wave = Waves::selectWaveOrNull()
                    return if wave.nil?
                    Waves::landing(wave)
                }
            end
        }
    end

    # Waves::access(wave)
    def self.access(wave)
        uuid = wave["uuid"]
        
        accessContent = lambda{|wave|
            if wave["contentType"] == "Line" then

            end
            if wave["contentType"] == "Url" then
                Utils::openUrlUsingSafari(wave["payload"])
            end
        }

        nxball = BankExtended::makeNxBall([uuid, "WAVES-A81E-4726-9F17-B71CAD66D793"])

        accessContent.call(wave)

        loop {

            break if CoreDataTx::getObjectByIdOrNull(wave["uuid"]).nil? # Could have been destroyed during landing

            system("clear")

            puts "#{Waves::toString(wave)} (#{BankExtended::runningTimeString(nxball)})"
            puts "note: #{KeyValueStore::getOrNull(nil, "b8b66f79-d776-425c-a00c-d0d1e60d865a:#{wave["uuid"]}")}".yellow

            command = LucilleCore::askQuestionAnswerAsString("> [actions: 'access', 'note:' , 'done', <datecode>, 'landing', 'detach running', 'exit'] action : ")

            break if command == "exit"

            if command == "++" then
                DoNotShowUntil::setUnixtime(uuid, Time.new.to_i+3600)
                break
            end

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(uuid, unixtime)
            end

            if command == "access" then
                accessContent.call(wave)
            end

            if command == "note:" then
                note = LucilleCore::askQuestionAnswerAsString("note: ")
                KeyValueStore::set(nil, "b8b66f79-d776-425c-a00c-d0d1e60d865a:#{wave["uuid"]}", note)
                next
            end

            if command == "done" then
                Waves::performDone(wave)
                break
            end

            if command == "landing" then
                Waves::landing(wave)
            end

            if command == "detach running" then
                DetachedRunning::issueNew2(Waves::toString(wave), Time.new.to_f, [uuid, "WAVES-A81E-4726-9F17-B71CAD66D793"])
                Waves::performDone(wave)
            end
        }
        
        BankExtended::closeNxBall(nxball, true)
    end

    # Waves::ensurePrioritySettings()
    def self.ensurePrioritySettings()
        CoreDataTx::getObjectsBySchema("wave")
            .each{|wave|
                if Waves::getPriorityOrNull(wave).nil? then
                    if LucilleCore::askQuestionAnswerAsBoolean("'#{Waves::toString(wave)}' is high priority ? ") then
                        Waves::setPriority(wave, "ns:high")
                    else
                        Waves::setPriority(wave, "ns:low")
                    end
                end
            }
    end

    # -------------------------------------------------------------------------

    # Waves::toNS16OrNull(wave)
    def self.toNS16OrNull(wave)
        uuid = wave["uuid"]
        {
            "uuid"     => uuid,
            "announce" => Waves::toString(wave),
            "access"   => lambda { Waves::access(wave) },
            "done"     => lambda { Waves::performDone(wave) },
            "wave"     => wave
        }
    end

    # Waves::ns16s()
    def self.ns16s()
        Waves::ensurePrioritySettings()
        CoreDataTx::getObjectsBySchema("wave")
            .map{|wave| Waves::toNS16OrNull(wave) }
            .compact
    end

    # Waves::ns16sHighPriority()
    def self.ns16sHighPriority()
        Waves::ns16s()
            .select{|ns16| Waves::getPriorityOrNull(ns16["wave"]) == "ns:high" }
    end

    # Waves::ns16sLowPriority()
    def self.ns16sLowPriority()
        Waves::ns16s()
            .select{|ns16| Waves::getPriorityOrNull(ns16["wave"]) == "ns:low" }
    end

    # Waves::dailyDoneCountAverage()
    def self.dailyDoneCountAverage()
        (
            Bank::valueOverTimespan("WAVES-DONE-IMPACT-8F82-BFB47E4541A2", 86400*7)+1
        ).to_f/7
    end

    # Waves::todayDoneCountRatio()
    def self.todayDoneCountRatio()
        Bank::valueAtDate("WAVES-DONE-IMPACT-8F82-BFB47E4541A2", Utils::today()).to_f/Waves::dailyDoneCountAverage()
    end

    # Waves::ns17sLowPriority()
    def self.ns17sLowPriority()
        [
            {
                "ratio" => Waves::todayDoneCountRatio(),
                "ns16s" => Waves::ns16sLowPriority()
            }
        ]
    end

    # Waves::nx19s()
    def self.nx19s()
        CoreDataTx::getObjectsBySchema("wave").map{|item|
            {
                "announce" => Waves::toString(item),
                "lambda"   => lambda { Waves::access(item) }
            }
        }
    end
end
