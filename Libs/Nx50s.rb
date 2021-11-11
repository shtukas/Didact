# encoding: UTF-8

class Nx50DoneCounter

    # Nx50DoneCounter::increaseDateCount(date)
    def self.increaseDateCount(date)
        count = KeyValueStore::getOrDefaultValue(nil, "3ed4c841-3a98-47b6-8c22-9a006e0d70c5:#{date}", "0").to_i
        KeyValueStore::set(nil, "3ed4c841-3a98-47b6-8c22-9a006e0d70c5:#{date}", count+1)
    end

    # Nx50DoneCounter::increaseTodayCount()
    def self.increaseTodayCount()
        Nx50DoneCounter::increaseDateCount(Utils::today())
    end

    # Nx50DoneCounter::getDateCount(date)
    def self.getDateCount(date)
        KeyValueStore::getOrDefaultValue(nil, "3ed4c841-3a98-47b6-8c22-9a006e0d70c5:#{date}", "0").to_i
    end

    # Nx50DoneCounter::getPastNDaysCount(n)
    def self.getPastNDaysCount(n)
        (0..n)
            .map{|i| Utils::nDaysInTheFuture(-i) }
            .map{|date| Nx50DoneCounter::getDateCount(date) }
            .inject(0, :+)
    end

    # Nx50DoneCounter::rate()
    def self.rate()
        Nx50DoneCounter::getPastNDaysCount(30).to_f/30
    end
end

class Nx50s

    # Nx50s::databaseFilepath2()
    def self.databaseFilepath2()
        "#{Utils::catalystDataCenterFolderpath()}/Items/Nx50s.sqlite3"
    end

    # Nx50s::nx50s()
    def self.nx50s()
        db = SQLite3::Database.new(Nx50s::databaseFilepath2())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _items_ order by _unixtime_") do |row|
            answer << {
                "uuid"        => row["_uuid_"],
                "unixtime"    => row["_unixtime_"],
                "description" => row["_description_"],
                "coreDataId"  => row["_coreDataId_"],
                "domain"      => row["_domain_"]
            }
        end
        db.close
        answer
    end

    # Nx50s::nx50sForDomain(domain)
    def self.nx50sForDomain(domain)
        db = SQLite3::Database.new(Nx50s::databaseFilepath2())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _items_ where _domain_=? order by _unixtime_", [domain]) do |row|
            answer << {
                "uuid"        => row["_uuid_"],
                "unixtime"    => row["_unixtime_"],
                "description" => row["_description_"],
                "coreDataId"  => row["_coreDataId_"],
                "domain"      => row["_domain_"]
            }
        end
        db.close
        answer
    end

    # Nx50s::commitItemToDatabase(item)
    def self.commitItemToDatabase(item)
        db = SQLite3::Database.new(Nx50s::databaseFilepath2())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _items_ where _uuid_=?", [item["uuid"]]
        db.execute "insert into _items_ (_uuid_, _unixtime_, _description_, _coreDataId_, _domain_) values (?,?,?,?,?)", [item["uuid"], item["unixtime"], item["description"], item["coreDataId"], item["domain"]]
        db.commit 
        db.close
    end

    # Nx50s::getItemByUUIDOrNull(uuid)
    def self.getItemByUUIDOrNull(uuid)
        db = SQLite3::Database.new(Nx50s::databaseFilepath2())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        item = nil
        db.execute( "select * from _items_ where _uuid_=?" , [uuid] ) do |row|
            item = {
                "uuid"        => row["_uuid_"],
                "unixtime"    => row["_unixtime_"],
                "description" => row["_description_"],
                "coreDataId"  => row["_coreDataId_"],
                "domain"      => row["_domain_"]
            }
        end
        db.close
        item
    end

    # Nx50s::delete(uuid)
    def self.delete(uuid)
        db = SQLite3::Database.new(Nx50s::databaseFilepath2())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _items_ where _uuid_=?", [uuid]
        db.commit 
        db.close
    end

    # --------------------------------------------------
    # Makers

    # Nx50s::interactivelyDetermineNewItemUnixtimeManuallyPosition(domain)
    def self.interactivelyDetermineNewItemUnixtimeManuallyPosition(domain)
        system("clear")
        items = Nx50s::nx50sForDomain(domain).first(Utils::screenHeight()-3)
        return Time.new.to_f if items.size == 0
        items.each_with_index{|item, i|
            puts "[#{i.to_s.rjust(2)}] #{Nx50s::toString(item)}"
        }
        puts "new first | <n> # index of previous item".yellow
        command = LucilleCore::askQuestionAnswerAsString("> ")
        if command == "new first" then
            return items[0]["unixtime"]-1 
        else
            # Here we interpret as index of an element
            i = command.to_i
            items = items.drop(i)
            if items.size == 0 then
                return Time.new.to_f
            end
            if items.size == 1 then
                return items[0]["unixtime"]+1 
            end
            if items.size >= 2 then
                return (items[0]["unixtime"]+items[1]["unixtime"]).to_f/2
            end
            raise "fa7e03a4-ce26-40c4-82d5-151f98908dca"
        end
        system('clear')
    end

    # Nx50s::getNewMinUnixtime(domain)
    def self.getNewMinUnixtime(domain)
        items = Nx50s::nx50sForDomain(domain)
        if items.empty? then
            return Time.new.to_f
        end
        items.map{|item| item["unixtime"] }.min - 1
    end

    # Nx50s::randomUnixtimeWithinTop10(domain)
    def self.randomUnixtimeWithinTop10(domain)
        items = Nx50s::nx50sForDomain(domain).first(10)
        if items.empty? then
            return Time.new.to_f
        end
        lowerbound = items.map{|item| item["unixtime"] }.min
        upperbound = items.map{|item| item["unixtime"] }.max
        lowerbound + rand * (upperbound-lowerbound)
    end

    # Nx50s::randomUnixtimeWithinRange(domain, n1, n2)
    def self.randomUnixtimeWithinRange(domain, n1, n2)
        items = Nx50s::nx50sForDomain(domain).drop(n1).first(n2-n1)
        if items.empty? then
            return Time.new.to_f
        end
        lowerbound = items.map{|item| item["unixtime"] }.min
        upperbound = items.map{|item| item["unixtime"] }.max
        lowerbound + rand * (upperbound-lowerbound)
    end

    # Nx50s::interactivelyDetermineNewItemUnixtime(domain)
    def self.interactivelyDetermineNewItemUnixtime(domain)
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("unixtime type", ["new first", "top 10", "manually position", "last (default)"])
        if type == "new first" then
            return Nx50s::getNewMinUnixtime(domain)
        end
        if type == "top 10" then
            return Nx50s::randomUnixtimeWithinTop10(domain)
        end
        if type == "manually position" then
            return Nx50s::interactivelyDetermineNewItemUnixtimeManuallyPosition(domain)
        end
        if type == "last (default)" then
            return Time.new.to_i
        end
        if type.nil? then
            return Time.new.to_i
        end
        raise "13a8d479-3d49-415e-8d75-7d0c5d5c695e"
    end

    # Nx50s::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        uuid = LucilleCore::timeStringL22()
        description = LucilleCore::askQuestionAnswerAsString("description (empty for abort): ")
        if description == "" then
            return nil
        end
        coreDataId = CoreData::interactivelyCreateANewDataObjectReturnIdOrNull()
        domain = Domain::interactivelySelectDomain()
        unixtime = Nx50s::interactivelyDetermineNewItemUnixtime(domain)
        Nx50s::commitItemToDatabase({
            "uuid"        => uuid,
            "unixtime"    => unixtime,
            "description" => description,
            "coreDataId"  => coreDataId,
            "domain"      => domain
        })
        Nx50s::getItemByUUIDOrNull(uuid)
    end

    # Nx50s::issueItemUsingText(text, unixtime, domain)
    def self.issueItemUsingText(text, unixtime, domain)
        uuid        = LucilleCore::timeStringL22()
        description = text.strip.lines.first.strip || "todo text @ #{Time.new.to_s}" 
        coreDataId  = CoreData::issueTextDataObjectUsingText(text)
        Nx50s::commitItemToDatabase({
            "uuid"        => uuid,
            "unixtime"    => unixtime,
            "description" => description,
            "coreDataId"  => coreDataId,
            "domain"      => domain
        })
        Nx50s::getItemByUUIDOrNull(uuid)
    end

    # Nx50s::issueItemUsingLine(line)
    def self.issueItemUsingLine(line)
        uuid     = LucilleCore::timeStringL22()
        domain   = Domain::interactivelySelectDomain()
        unixtime = Nx50s::interactivelyDetermineNewItemUnixtime(domain)
        Nx50s::commitItemToDatabase({
            "uuid"        => uuid,
            "unixtime"    => unixtime,
            "description" => description,
            "coreDataId"  => nil,
            "domain"      => domain
        })
        Nx50s::getItemByUUIDOrNull(uuid)
    end

    # Nx50s::issueItemUsingLocation(location, unixtime, domain)
    def self.issueItemUsingLocation(location, unixtime, domain)
        uuid        = LucilleCore::timeStringL22()
        description = File.basename(location)
        coreDataId = CoreData::issueAionPointDataObjectUsingLocation(location)
        Nx50s::commitItemToDatabase({
            "uuid"        => uuid,
            "unixtime"    => unixtime,
            "description" => description,
            "coreDataId"  => coreDataId,
            "domain"      => domain
        })
        Nx50s::getItemByUUIDOrNull(uuid)
    end

    # Nx50s::issueItemUsingURL(url domain)
    def self.issueItemUsingURL(url, domain)
        uuid        = LucilleCore::timeStringL22()
        unixtime    = Time.new.to_f
        description = url
        coreDataId = CoreData::issueUrlPointDataObjectUsingUrl(url)
        Nx50s::commitItemToDatabase({
            "uuid"        => uuid,
            "unixtime"    => unixtime,
            "description" => description,
            "coreDataId"  => coreDataId,
            "domain"      => domain
        })
        Nx50s::getItemByUUIDOrNull(uuid)
    end

    # --------------------------------------------------
    # Operations

    # Nx50s::updateDescription(uuid, description)
    def self.updateDescription(uuid, description)
        db = SQLite3::Database.new(Nx50s::databaseFilepath2())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "update _items_ set _description_=? where _uuid_=?", [description, uuid]
        db.commit 
        db.close
    end

    # Nx50s::getItemType(item)
    def self.getItemType(item)
        type = KeyValueStore::getOrNull(nil, "bb9de7f7-022c-4881-bf8d-fb749cd2cc77:#{item["coreDataId"]}")
        return type if type
        type1 = CoreData::contentTypeOrNull(item["coreDataId"])
        type2 = type1 || "line"
        KeyValueStore::set(nil, "bb9de7f7-022c-4881-bf8d-fb749cd2cc77:#{item["coreDataId"]}", type2)
        type2
    end

    # Nx50s::toString(item)
    def self.toString(item)
        "[nx50] #{item["description"]} (#{Nx50s::getItemType(item)})"
    end

    # Nx50s::toStringForNS19(item)
    def self.toStringForNS19(item)
        "[nx50] #{item["description"]}"
    end

    # Nx50s::toStringForNS16(item, rt)
    def self.toStringForNS16(item, rt)
        "[nx50] (#{"%4.2f" % rt}) #{item["description"]} (#{Nx50s::getItemType(item)})"
    end

    # Nx50s::complete(nx50)
    def self.complete(nx50)
        Nx50s::delete(nx50["uuid"])
        Nx50DoneCounter::increaseTodayCount()
    end

    # Nx50s::accessContent(item)
    def self.accessContent(item)
        if item["coreDataId"].nil? then
            puts "description: #{item["description"]}"
            LucilleCore::pressEnterToContinue()
            return
        end
        CoreData::accessWithOptionToEdit(item["coreDataId"])
    end

    # --------------------------------------------------
    # nx16s

    # Nx50s::processInboxLastAtDomain(foldername, domain)
    def self.processInboxLastAtDomain(foldername, domain)
        LucilleCore::locationsAtFolder("/Users/pascal/Desktop/#{foldername}").each{|location|
            puts "[Nx50] #{domain} (last) #{location}"
            Nx50s::issueItemUsingLocation(location, Time.new.to_f, domain)
            LucilleCore::removeFileSystemLocation(location)
        }
    end

    # Nx50s::run(nx50)
    def self.run(nx50)

        system("clear")

        uuid = nx50["uuid"]
        puts "#{Nx50s::toString(nx50)}".green
        puts "Starting at #{Time.new.to_s}"

        nxball = NxBalls::makeNxBall([uuid, Domain::getDomainBankAccount(nx50["domain"])])

        thr = Thread.new {
            loop {
                sleep 60

                if (Time.new.to_i - nxball["cursorUnixtime"]) >= 600 then
                    nxball = NxBalls::upgradeNxBall(nxball, false)
                end

                if (Time.new.to_i - nxball["startUnixtime"]) >= 3600 then
                    Utils::onScreenNotification("Catalyst", "Nx50 item running for more than an hour")
                end
            }
        }

        loop {

            system("clear")

            puts "#{Nx50s::toString(nx50)} (#{NxBalls::runningTimeString(nxball)})".green
            puts "uuid: #{uuid}".yellow
            puts "coreDataId: #{nx50["coreDataId"]}".yellow
            puts "RT: #{BankExtended::stdRecoveredDailyTimeInHours(uuid)}".yellow
            puts "DoNotDisplayUntil: #{DoNotShowUntil::getDateTimeOrNull(nx50["uuid"])}".yellow

            puts ""
            puts CoreData::toTextOrNull(nx50["coreDataId"])
            puts ""

            note = StructuredTodoTexts::getNoteOrNull(uuid)
            if note then
                puts "-- Note ------------------"
                puts note.strip
                puts ""
            end

            puts "access | note | [] | <datecode> | detach running | pause | pursue | update description | update contents | update unixtime | domain | show json | destroy (gg) | exit".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == "exit"

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(uuid, unixtime)
                break
            end

            if Interpreting::match("access", command) then
                Nx50s::accessContent(nx50)
                next
            end

            if command == "note" then
                note = Utils::editTextSynchronously(StructuredTodoTexts::getNoteOrNull(nx50["uuid"]) || "")
                StructuredTodoTexts::setNote(uuid, note)
                next
            end

            if command == "[]" then
                StructuredTodoTexts::applyT(uuid)
                note = StructuredTodoTexts::getNoteOrNull(uuid)
                if note then
                    puts "-- Note -------------------"
                    puts note.strip
                    puts ""
                end
                next
            end

            if Interpreting::match("detach running", command) then
                DetachedRunning::issueNew2(Nx50s::toString(nx50), Time.new.to_i, [uuid])
                break
            end

            if Interpreting::match("pause", command) then
                NxBalls::closeNxBall(nxball, true)
                puts "Starting pause at #{Time.new.to_s}"
                LucilleCore::pressEnterToContinue()
                nxball = NxBalls::makeNxBall([uuid])
                next
            end

            if command == "pursue" then
                # We close the ball and issue a new one
                NxBalls::closeNxBall(nxball, true)
                nxball = NxBalls::makeNxBall([uuid])
                next
            end

            if Interpreting::match("update description", command) then
                description = Utils::editTextSynchronously(nx50["description"]).strip
                if description.size > 0 then
                    Nx50s::updateDescription(nx50["uuid"], description)
                    nx50 = Nx50s::getItemByUUIDOrNull(nx50["uuid"])
                end
                next
            end

            if Interpreting::match("update contents", command) then
                coreDataId = CoreData::interactivelyCreateANewDataObjectReturnIdOrNull()
                return if coreDataId.nil?
                nx50["coreDataId"] = coreDataId
                Nx50s::commitItemToDatabase(nx50)
                next
            end

            if Interpreting::match("update unixtime", command) then
                domain = nx50["domain"]
                nx50["unixtime"] = Nx50s::interactivelyDetermineNewItemUnixtime(domain)
                Nx50s::commitItemToDatabase(nx50)
                next
            end

            if Interpreting::match("domain", command) then
                nx50["domain"] = Domain::interactivelySelectDomain()
                Nx50s::commitItemToDatabase(nx50)
                break
            end

            if Interpreting::match("show json", command) then
                puts JSON.pretty_generate(nx50)
                LucilleCore::pressEnterToContinue()
                break
            end

            if command == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{Nx50s::toString(nx50)}' ? ", true) then
                    Nx50s::complete(nx50)
                    break
                end
                next
            end

            if command == "gg" then
                Nx50s::complete(nx50)
                break
            end

        }

        thr.exit

        NxBalls::closeNxBall(nxball, true)
    end

    # Nx50s::ns16OrNull(nx50)
    def self.ns16OrNull(nx50)
        uuid = nx50["uuid"]
        return nil if !DoNotShowUntil::isVisible(uuid)
        return nil if !InternetStatus::ns16ShouldShow(uuid)
        rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)
        note = StructuredTodoTexts::getNoteOrNull(uuid)
        noteStr = note ? " [note]" : ""
        announce = "#{Nx50s::toStringForNS16(nx50, rt)}#{noteStr} (rt: #{rt.round(2)})".gsub("(0.00)", "      ")
        {
            "uuid"     => uuid,
            "announce" => announce,
            "commands"    => ["..", "done"],
            "interpreter" => lambda {|command|
                if command == ".." then
                    Nx50s::run(nx50)
                end
                if command == "done" then
                    if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{Nx50s::toString(nx50)}' ? ", true) then
                        Nx50s::complete(nx50)
                    end
                end
            },
            "run" => lambda {
                Nx50s::run(nx50)
            },
            "rt" => rt
        }
    end

    # Nx50s::hudThreshold(domain)
    def self.hudThreshold(domain)
        (domain == "(work)") ? 2 : 1
    end

    # Nx50s::headCapacity(domain)
    def self.headCapacity(domain)
        (domain == "(work)") ? 3 : 5
    end

    # Nx50s::structure(domain)
    def self.structure(domain)
        getTopStoredPool = lambda {|domain|
            JSON.parse(KeyValueStore::getOrDefaultValue(nil, "2b9c7de0-5392-422c-9bb4-e1c04553d633:#{Utils::today()}:#{domain}", "[]"))
        }

        ns16BelongsToPool = lambda {|ns16, uuids|
            uuids.include?(ns16["uuid"])
        }

        setTopStoredPool = lambda{|domain, uuids|
            KeyValueStore::set(nil, "2b9c7de0-5392-422c-9bb4-e1c04553d633:#{Utils::today()}:#{domain}", JSON.generate(uuids))
        }

        threshold = Nx50s::hudThreshold(domain)

        q1, q2 = Nx50s::nx50sForDomain(domain)
                    .map{|item| Nx50s::ns16OrNull(item) }
                    .compact
                    .partition{|ns16| ns16["rt"] >= threshold }

        # q1: hud
        # q2: head and tail

        pool = getTopStoredPool.call(domain)

        q3, q4 = q2.partition{|ns16| ns16BelongsToPool.call(ns16, pool) }

        # q3: head
        # q4: tail

        # If head is empty, we need a new one

        if q3.empty? then
            q3 = q4.first(Nx50s::headCapacity(domain))
            q4 = q4.drop(Nx50s::headCapacity(domain))
            setTopStoredPool.call(domain, q3.map{|ns16| ns16["uuid"] })
        end

        q3 = q3.sort{|x1, x2| x1["rt"] <=> x2["rt"] }
        {
            "overflow" => q1,
            "head"     => q3,
            "tail"     => q4
        }
    end

    # Nx50s::ns16s(domain)
    def self.ns16s(domain)

        Quarks::importspread()
        Nx50s::processInboxLastAtDomain("(eva)-last", "(eva)")
        Nx50s::processInboxLastAtDomain("(work)-last", "(work)")

        structure = Nx50s::structure(domain)
        structure["head"] + structure["tail"]
    end

    # --------------------------------------------------

    # Nx50s::nx19s()
    def self.nx19s()
        Nx50s::nx50s().map{|item|
            {
                "uuid"     => item["uuid"],
                "announce" => Nx50s::toStringForNS19(item),
                "lambda"   => lambda { Nx50s::run(item) }
            }
        }
    end
end
