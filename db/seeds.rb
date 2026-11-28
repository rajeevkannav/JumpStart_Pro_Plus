email = ENV["DEMO_EMAIL"]
password = ENV["DEMO_PASSWORD"]

if email.present? && password.present?
  user = User.find_or_initialize_by(email_address: email)
  user.password = password
  user.password_confirmation = password
  user.email_confirmed_at = Time.current
  if user.save
    puts "Demo account seeded: #{email}"
  else
    puts "Failed to seed demo account: #{user.errors.full_messages.join(', ')}"
  end
else
  puts "Skipping demo account seed: DEMO_EMAIL or DEMO_PASSWORD missing."
end
