class MakeEmailNullableAndPartialIndex < ActiveRecord::Migration[7.0]
  def change
    # 1) Remove the old unique index on :email (the name may differ in your schema).
    #    From your schema, it's named: "index_users_on_email"
    remove_index :users, name: "index_users_on_email"

    # 2) Allow email to be NULL
    change_column_null :users, :email, true

    # 3) Create a new partial unique index for non-NULL emails
    #    This means phone_only users (with email=NULL or blank) won't collide.
    add_index :users, :email, unique: true, where: "email IS NOT NULL"
  end
end
