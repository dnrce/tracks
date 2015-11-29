require 'test_helper'

class UserTest < ActiveSupport::TestCase
  fixtures :users, :preferences, :projects, :contexts, :todos, :recurring_todos

  def setup
    @admin_user = User.find(1)
    @other_user = users(:other_user)
  end

  # Test an admin user model
  #
  def test_admin
    assert_kind_of User, @admin_user
    assert_equal 1, @admin_user.id
    assert_equal "admin", @admin_user.login
    assert_not_nil @admin_user.crypted_password
    assert_not_nil @admin_user.token
    assert @admin_user.is_admin
  end

  # Test a non-admin user model
  def test_non_admin
    assert_kind_of User, @other_user
    assert_equal "jane", @other_user.login
    assert_not_nil @other_user.crypted_password
    assert_not_nil @other_user.token
    assert @other_user.is_admin == false || @other_user.is_admin == 0
  end

  # ============================================
  # Validations
  # ============================================

  # Test a password shorter than 5 characters
  #
  def test_validate_short_password
    assert_no_difference 'User.count' do
      u = create_user :password => generate_random_string(4)
      assert_equal "is too short (minimum is 5 characters)", u.errors[:password][0]
    end
  end

  def test_validate_long_password
    assert_no_difference 'User.count' do
      u = create_user :password => generate_random_string(73)
      assert_equal "is too long (maximum is 72 characters)", u.errors[:password][0]
    end
  end

  def test_validate_correct_length_password
    assert_difference 'User.count' do
      create_user :password => generate_random_string(6)
    end
  end

  def test_validate_missing_password
    assert_no_difference 'User.count' do
      u = create_user :password => ''
      assert_equal ["can't be blank", "is too short (minimum is 5 characters)"], u.errors[:password]
    end
  end

  def test_validate_short_login
    assert_no_difference 'User.count' do
      u = create_user :login => 'ba'
      assert_equal "is too short (minimum is 3 characters)", u.errors[:login][0]
    end
  end

  def test_validate_long_login
    assert_no_difference 'User.count' do
      u = create_user :login => generate_random_string(81)
      assert_equal "is too long (maximum is 80 characters)", u.errors[:login][0]
    end
  end

  def test_validate_correct_length_login
    assert_difference 'User.count' do
      create_user :login => generate_random_string(6)
    end
  end

  def test_validate_missing_login
    assert_no_difference 'User.count' do
      u = create_user :login => ''
      assert_equal ["can't be blank", "is too short (minimum is 3 characters)"], u.errors[:login]
    end
  end

  def test_display_name_with_first_and_last_name_set
    @other_user.first_name = "Jane"
    @other_user.last_name = "Doe"
    assert_equal "Jane Doe", @other_user.display_name
  end

  def test_display_name_with_first_name_set
    @other_user.first_name = "Jane"
    @other_user.last_name = nil
    assert_equal "Jane", @other_user.display_name
  end

  def test_display_name_with_last_name_set
    @other_user.first_name = nil
    @other_user.last_name = "Doe"
    assert_equal "Doe", @other_user.display_name
  end

  def test_display_name_with_neither_first_nor_last_name_set
    @other_user.first_name = nil
    @other_user.last_name = nil
    assert_equal @other_user.login, @other_user.display_name
  end

  def test_prefs_is_short_for_preference
    assert_equal @admin_user.preference, @admin_user.prefs
  end

  def test_to_param_returns_login
    assert_equal @admin_user.login, @admin_user.to_param
  end

  def test_change_password
    assert_not_nil User.authenticate(@admin_user.login, "abracadabra")
    @admin_user.change_password("foobar", "foobar")
    @admin_user.reload
    assert_nil User.authenticate(@admin_user.login, "abracadabra")
    assert_not_nil User.authenticate(@admin_user.login, "foobar")
  end

  def test_projects_next_project
    moremoney = projects(:moremoney)
    next_project = @admin_user.projects.next_from(moremoney)
    assert_equal projects(:gardenclean), next_project
  end

  def test_projects_previous_project
    moremoney = projects(:moremoney)
    previous_project = @admin_user.projects.previous_from(moremoney)
    assert_equal projects(:timemachine), previous_project
  end

  def test_projects_next_project_nil
    gardenclean = projects(:gardenclean)
    next_project = @admin_user.projects.next_from(gardenclean)
    assert_nil next_project
  end

  def test_projects_previous_project_nil
    timemachine = projects(:timemachine)
    previous_project = @admin_user.projects.previous_from(timemachine)
    assert_nil previous_project
  end

  def test_no_users_yet
    assert !User.no_users_yet?
    User.delete_all
    assert User.no_users_yet?
  end

  def test_generate_token_updates_token
    assert_value_changed @admin_user, :token do
      @admin_user.send :generate_token
    end
  end

  def test_find_admin
    assert_equal @admin_user, User.find_admin
  end

  def test_validates_auth_type
    @other_user.auth_type = 'dnacheck'
    assert !@other_user.save
    assert_equal 1, @other_user.errors.count
    assert_equal ["not a valid authentication type (dnacheck)"], @other_user.errors[:auth_type]
  end

  def test_find_context_by_params
    u = @admin_user
    c = contexts(:agenda)
    assert_equal c, u.contexts.find_by_params('id' => c.id)
    assert_equal c, u.contexts.find_by_params('context_id' => c.id)
  end

  def test_find_project_by_params
    u = @admin_user
    p = projects(:timemachine)
    assert_equal p, u.projects.find_by_params('id' => p.id)
    assert_equal p, u.projects.find_by_params('project_id' => p.id)
  end

  def test_update_project_positions
    u = @admin_user
    current_order = u.projects.map(&:id)
    new_order = current_order.rotate
    u.projects.update_positions new_order
    assert_equal new_order, u.projects.reload.map(&:id)
  end

  def test_find_and_activate_deferred_todos_that_are_ready
    assert_equal 1, @admin_user.deferred_todos.count
    @admin_user.deferred_todos[0].show_from = Time.zone.now - 5.seconds
    @admin_user.deferred_todos[0].save(:validate => false)
    @admin_user.deferred_todos.reload
    @admin_user.deferred_todos.find_and_activate_ready
    @admin_user.deferred_todos.reload
    assert_equal 0, @admin_user.deferred_todos.count
  end

  def test_sort_active_projects_alphabetically
    u = users(:admin_user)
    u.projects.alphabetize(:state => "active")
    assert_equal 1, projects(:timemachine).position
    assert_equal 2, projects(:gardenclean).position
    assert_equal 3, projects(:moremoney).position
  end

  def test_sort_active_projects_alphabetically_case_insensitive
    u = users(:admin_user)
    projects(:timemachine).name = projects(:timemachine).name.downcase
    projects(:timemachine).save!
    u.projects.alphabetize(:state => "active")
    assert_equal 1, projects(:timemachine).position
    assert_equal 2, projects(:gardenclean).position
    assert_equal 3, projects(:moremoney).position
  end

  def test_should_create_user
    assert_difference 'User.count' do
      user = create_user
      assert !user.new_record?, "#{user.errors.full_messages.to_sentence}"
    end
  end

  def test_should_require_login
    assert_no_difference 'User.count' do
      u = create_user(:login => nil)
      assert u.errors[:login][0]
    end
  end

  def test_should_require_password
    assert_no_difference 'User.count' do
      u = create_user(:password => nil)
      assert u.errors[:password][0]
    end
  end

  def test_should_require_password_confirmation
    assert_no_difference 'User.count' do
      u = create_user(:password_confirmation => nil)
      assert u.errors[:password_confirmation][0]
    end
  end

  def test_should_reset_password
    users(:other_user).update_attributes(:password => 'new password', :password_confirmation => 'new password')
    assert_equal users(:other_user), User.authenticate('jane', 'new password')
  end

  def test_should_not_rehash_password
    users(:other_user).update_attributes(:login => 'jane2')
    assert_equal users(:other_user), User.authenticate('jane2', 'sesame')
  end

  def test_should_authenticate_user
    assert_equal users(:other_user), User.authenticate('jane', 'sesame')
  end

  def test_should_set_remember_token
    users(:other_user).remember_me
    assert_not_nil users(:other_user).remember_token
    assert_not_nil users(:other_user).remember_token_expires_at
  end

  def test_should_unset_remember_token
    users(:other_user).remember_me
    assert_not_nil users(:other_user).remember_token
    users(:other_user).forget_me
    assert_nil users(:other_user).remember_token
  end

  def test_password_matches
    assert_not_nil User.authenticate(@admin_user.login, "abracadabra")
    assert_nil User.authenticate(@admin_user.login, "incorrect")
  end

  def test_update_positions_of_contexts
    u = users(:admin_user)
    current_order = u.contexts.map(&:id)
    new_order = current_order.rotate
    u.contexts.update_positions new_order
    assert_equal new_order, u.contexts.reload.map(&:id)
  end

  def test_cache_notes_count_for_projects
    u = users(:admin_user)
    u.projects.each do |p|
      assert_nil p.cached_note_count, "notes count should not be there"
    end

    u.projects.cache_note_counts

    u.projects.each do |p|
      assert !p.cached_note_count.nil?, "notes count should be there"
    end
  end

  def test_actionize_projects
    u = users(:admin_user)
    project_list = [projects(:timemachine), projects(:moremoney), projects(:gardenclean)]
    assert_equal project_list, u.projects

    u.projects.actionize

    actionized_project_list = [projects(:gardenclean), projects(:moremoney), projects(:timemachine)]
    assert_equal actionized_project_list, u.projects.reload
  end

  def test_remember_token
    u = users(:admin_user)
    assert_nil u.remember_token
    assert_nil u.remember_token_expires_at

    # set token on 2013-feb-28
    travel_to Time.local(2013, 2, 28) do
      u.remember_me
      assert_not_nil u.remember_token_expires_at

      assert u.remember_token?
    end

    # token should be valid after 5 days
    travel_to Time.local(2013, 3, 5) do
      assert u.remember_token?
    end

    # token should not be valid after more than 2 weeks
    travel_to Time.local(2013, 3, 28) do
      assert !u.remember_token?
    end
  end

  def test_count_todos_by_group
    u = users(:admin_user)

    # test group counts for projects and contexts
    project_counts = {
      0 => 6,
      projects(:timemachine).id => 3,
      projects(:moremoney).id => 4,
      projects(:gardenclean).id => 4
    }
    assert_equal project_counts.sort.map { |k, v| v }, u.todos.count_by_group(:project_id).values

    context_counts = {
      contexts(:agenda).id => 7,
      contexts(:call).id => 3,
      contexts(:email).id => 1,
      contexts(:errand).id => 3,
      contexts(:lab).id => 1,
      contexts(:library).id => 2
    }
    assert_equal context_counts.sort.map { |k, v| v }, u.todos.count_by_group(:context_id).values

    # add a todo to the first context and check that the count is increased
    u.todos.create!(:description => "yet another todo", :context => contexts(:agenda))
    context_counts[contexts(:agenda).id] += 1
    assert_equal context_counts.sort.map { |k, v| v }, u.todos.reload.count_by_group(:context_id).values
  end

  def test_deleting_user_deletes_all_related_data
    u = users(:admin_user)

    nr_of_todos = u.todos.count
    nr_of_projects = u.projects.count
    nr_of_contexts = u.contexts.count
    nr_of_rec_todos = u.recurring_todos.count
    nr_of_notes = u.notes.count
    nr_of_deps = (Dependency.where(predecessor_id: u.todos.pluck(:id)).pluck(:id) + Dependency.where(successor_id: u.todos.pluck(:id)).pluck(:id)).uniq.count

    expect_todos_count = Todo.count - nr_of_todos
    expect_projects_count = Project.count - nr_of_projects
    expect_contexts_count = Context.count - nr_of_contexts
    expect_rec_todos_count = RecurringTodo.count - nr_of_rec_todos
    expect_notes_count = Note.count - nr_of_notes
    expect_deps_count = Dependency.count - nr_of_deps

    u.destroy

    assert_equal expect_todos_count, Todo.count, "expected #{nr_of_todos} todos to be gone"
    assert_equal expect_projects_count, Project.count, "expected #{nr_of_projects} projects to be gone"
    assert_equal expect_contexts_count, Context.count, "expected #{nr_of_contexts} contexts to be gone"
    assert_equal expect_rec_todos_count, RecurringTodo.count, "expected #{nr_of_rec_todos} recurring todos to be gone"
    assert_equal expect_notes_count, Note.count, "expected #{nr_of_notes} notes to be gone"
    assert_equal expect_deps_count, Dependency.count, "expected #{nr_of_deps} dependencies to be gone"
  end

  protected

  def create_user(options = {})
    options[:password_confirmation] = options[:password] unless options.has_key?(:password_confirmation) || !options.has_key?(:password)
    User.create({ :login => 'quire', :password => 'quire', :password_confirmation => 'quire' }.merge(options))
  end

end
