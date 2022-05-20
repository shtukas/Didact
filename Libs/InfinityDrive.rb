
# encoding: UTF-8

class InfinityDrive

    # InfinityDrive::driveIsPlugged()
    def self.driveIsPlugged()
        File.exists?(Config::pathToInfinityDidactDataBankType1())
    end

    # InfinityDrive::ensureInfinityDrive()
    def self.ensureInfinityDrive()
        if !InfinityDrive::driveIsPlugged() then
            puts "I need Infinity. Please plug 🙏"
            LucilleCore::pressEnterToContinue()
            if !InfinityDrive::driveIsPlugged() then
                puts "Could not find Infinity 😞 Exiting."
                exit
            end
        end
    end
end
