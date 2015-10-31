require "test_helper"

class TodosHelpersTest < ActionView::TestCase
  include TodosHelper

  test "remote_edit_button" do
    t = todos(:call_bill)
    html = remote_edit_button(t)
    assert_equal "<a class=\"icon edit_item\" href=\"/todos/#{t.id}/edit\" id=\"icon_edit_todo_#{t.id}\" title=\"Edit the action &#39;Call Bill Gates to find out how much he makes per day&#39;\"><img align=\"absmiddle\" alt=\"Edit\" class=\"edit_item\" id=\"edit_icon_todo_#{t.id}\" src=\"/images/blank.png\" /></a>", html
  end

  test "remote_delete_menu" do
    t = todos(:call_bill)
    html = remote_delete_menu_item(t)
    assert_equal "<a class=\"icon_delete_item\" href=\"/todos/#{t.id}\" id=\"delete_todo_#{t.id}\" title=\"Delete action\" x_confirm_message=\"Are you sure that you want to delete the action &#39;Call Bill Gates to find out how much he makes per day&#39;?\">Delete</a>", html
  end

  test "remote_delete_dependency" do
    t = todos(:call_bill_gates_every_day)
    p = todos(:call_bill)
    html = remote_delete_dependency(t, p)
    assert_equal "<a class=\"delete_dependency_button\" href=\"/todos/#{t.id}/remove_predecessor\" x_predecessors_id=\"#{p.id}\"><img align=\"absmiddle\" alt=\"Blank\" class=\"delete_item\" src=\"/images/blank.png\" title=\"Remove dependency (does not delete the action)\" /></a>", html
  end

  test "remote_promote_to_project_menu_item" do
    t = todos(:call_bill)
    html = remote_promote_to_project_menu_item(t)
    assert_equal "<a class=\"icon_item_to_project\" href=\"/todos/#{t.id}/convert_to_project?_source_view=\" id=\"to_project_todo_#{t.id}\">Make project</a>", html
  end
end
