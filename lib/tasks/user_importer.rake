require 'csv'

namespace :user_importer do
  desc "Import users from a CSV file"
  task :import => :environment do |_|
    csv = <<-eos
email,first_name,groups
odyljones@gmail.com,Odyl,moderators
rifflejane@gmail.com,Gina,moderators
dana.glaser@odyl.net,Nina,moderators
charlee.vale@rifflebooks.com,Hannah,moderators
darcy.evans@odyl.net,Darcy,moderators
trey.barnett@odyl.net,Gina,moderators
jamesriffle@rifflebooks.com,Erica,moderators
marya.pasciuto@rifflebooks.com,Mary,moderators
kate.hutchings@odyl.net,Jennifer,moderators
rebecca.mullins@rifflebooks.com,Rebecca,moderators
kate.hutchings@rifflebooks.com,Kate,moderators
max.minckler@rifflebooks.com,Max,moderators
samantha.smith@rifflebooks.com,Lauren,moderators
carina.turchioe@odyl.net,Carina,moderators
krystal.sital@rifflebooks.com,Gina,moderators
janelle.ludowise@odyl.net,Amy,moderators
kidriffle@rifflebooks.com,Desirae,moderators
clare.mcbride@odyl.net,Louie,moderators
katecompetitions@hotmail.com,GreenLiving,moderators
anoukriffle@gmail.com,Anouk,moderators
max.minckler@odyl.net,Max,moderators
k_hutchings@hotmail.co.uk,Kate,moderators
ariel.birdoff@odyl.net,Jennifer,moderators
aruna@odyl.net,Riffle,moderators
chelsea.fought@rifflebooks.com,Chelsea,moderators
greg.fisher@rifflebooks.com,Gregory,moderators
eos
    CSV.foreach(csv, col_sep: ',', headers: true) do |new_user|

      user = User.where(email: new_user['email']).first
      if user
        new_groups = new_user_groups(new_user['groups']) - user.groups.map(&:name)
        user.groups << parse_user_groups(new_groups)

        puts "User #{new_user['email']} already exists and is not imported."
        puts ">> #{new_user['email']} was added to #{new_groups.join(',')}" unless new_groups.empty?
      else
        u = User.new({
          username: new_user['username'] || UserNameSuggester.suggest(new_user['email']),
          email: new_user['email'],
          password: SecureRandom.hex,
          name: new_user['name'],
          title: new_user['title'],
          approved: true,
          approved_by_id: -1
        })
        u.import_mode = true
        u.groups = parse_user_groups new_user['groups']
        u.save

        puts "Imported #{u.name} (#{u.email}) as #{u.username} to #{u.groups.map(&:name).join(',')}"
      end

    end
  end

  desc "Check usernames of users to be imported"
  task :check, [:csv_file] => [:environment] do |_, args|
    CSV.foreach(args[:csv_file], col_sep: ';', headers: true) do |new_user|

      if new_user['username']
        user = User.where(username: new_user['username']).first

        if user
          puts "Username #{new_user['username']} (#{new_user['email']}) already exists for user: #{user.name} (#{user.email})"
        else
          puts "Username #{new_user['username']} is free to use!"
        end

      else
        puts "No username supplied for #{new_user['email']}, ignoring..."
      end

    end
  end
end

def new_user_groups(groups)
  groups.split(',')
end

def parse_user_groups(groups)
  return [] if groups.blank?
  new_user_groups(groups).map do |group|
    Group.where(name: group).first
  end
end
