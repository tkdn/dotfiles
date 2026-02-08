function gitset
  set name tkdn
  set email tkdnation@gmail.com

  git config --local user.name $name
  git config --local user.email $email

  git config --local -l
end
