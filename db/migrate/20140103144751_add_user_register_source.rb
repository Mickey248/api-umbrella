class AddUserRegisterSource < Mongoid::Migration
  def self.up
    ApiUser.where(:registration_source => nil).all.each do |user|
      if(user.creator.present?)
        user.registration_source = "web_admin"
      else
        user.registration_source = "web"
      end
    end
  end

  def self.down
  end
end
