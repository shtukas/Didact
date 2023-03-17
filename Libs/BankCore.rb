# encoding: UTF-8

$BankVault = {}

class BankCore

    # ----------------------------------
    # Interface

    # BankCore::getValueAtDate(uuid, date)
    def self.getValueAtDate(uuid, date)
        BankCore::filepaths()
            .map{|filepath| BankCore::getValueAtDateInFile(filepath, uuid, date) }
            .inject(0, :+)
    end

    # BankCore::getValue(uuid)
    def self.getValue(uuid)
        BankCore::filepaths()
            .map{|filepath| BankCore::getValueInFile(filepath, uuid) }
            .inject(0, :+)
    end

    # BankCore::put(uuid, value)
    def self.put(uuid, value)
        BankCore::commit(uuid, Time.new.to_i, Time.new.to_s[0, 10], value)
    end

    # BankCore::commit(uuid, unixtime, date, value)
    def self.commit(uuid, unixtime, date, value)
        puts "BankCore::commit(#{uuid}, #{date}, #{value})"

        filepaths = BankCore::filepaths()

        filepath0 = BankCore::spawnNewDatabase()

        db = SQLite3::Database.new(filepath0)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "insert into bank (recordId, uuid, unixtime, date, value) values (?, ?, ?, ?, ?)", [SecureRandom.hex, uuid, unixtime, date, value]
        db.close
    end

    # ----------------------------------
    # Private (0)

    # BankCore::capacitybase()
    def self.capacitybase()
        50
    end

    # ----------------------------------
    # Private (1)

    # BankCore::spawnNewDatabase()
    def self.spawnNewDatabase()
        filepath = "#{Config::pathToDataCenter()}/Bank/#{CommonUtils::timeStringL22()}-#{CommonUtils::timeStringL22()}.sqlite3"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("create table bank (recordId text primary key, uuid text, unixtime float, date text, value float)", [])
        db.close
        filepath
    end

    # BankCore::filepaths()
    def self.filepaths()
        LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/Bank")
            .select{|filepath| filepath[-8, 8] == ".sqlite3" }
    end

    # ----------------------------------
    # Private (2)

    # BankCore::getValueAtDateInFile(filepath, uuid, date)
    def self.getValueAtDateInFile(filepath, uuid, date)
        # This function can be memoised because the database files are content addressed 🎉

        vaultkey = "#{filepath}:#{uuid}:#{date}"
        if $BankVault[vaultkey] then
            return $BankVault[vaultkey]
        end

        value = 0
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from bank where uuid=? and date=?", [uuid, date]) do |row|
            value = value + row["value"]
        end
        db.close

        $BankVault[vaultkey] = value

        value
    end

    # BankCore::getValueInFile(filepath, uuid)
    def self.getValueInFile(filepath, uuid)
        value = 0
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from bank where uuid=?", [uuid]) do |row|
            value = value + row["value"]
        end
        db.close
        value
    end

    # BankCore::fileManagement()
    def self.fileManagement()
        if BankCore::filepaths().size > BankCore::capacitybase()*2 then
            puts "BankCore file management".green
            while BankCore::filepaths().size > BankCore::capacitybase() do
                filepath1, filepath2 = BankCore::filepaths()

                db1 = SQLite3::Database.new(filepath1)
                db2 = SQLite3::Database.new(filepath2)

                # We move all the objects from db1 to db2

                db1.busy_timeout = 117
                db1.busy_handler { |count| true }
                db1.results_as_hash = true
                db1.execute("select * from bank", []) do |row|
                    db2.execute "delete from bank where recordId = ?", [row["recordId"]]
                    db2.execute "insert into bank (recordId, uuid, unixtime, date, value) values (?, ?, ?, ?, ?)", [row["recordId"], row["uuid"], row["unixtime"], row["date"], row["value"]]
                end

                db1.close
                db2.close

                # Let's now delete the first file 
                FileUtils.rm(filepath1)

                # And rename the second one
                filepath2v2 = "#{Config::pathToDataCenter()}/Bank/#{File.basename(filepath2)[0, 22]}-#{CommonUtils::timeStringL22()}.sqlite3"
                FileUtils.mv(filepath2, filepath2v2)
            end
        end
    end
end
