
defmodule GraphQL.Lang.AST.TypeInfo do
  @moduledoc ~S"""
  TypeInfo maintains type metadata pertaining to the current node of a query AST,
  and is generated by the TypeInfoVistor.

  The type information is made available to validation rules.
  """

  alias GraphQL.Util.Stack
  alias GraphQL.Type.{
    CompositeType,
    Introspection,
    List,
    NonNull,
    Interface,
    ObjectType
  }

  defstruct schema: nil,
            type_stack: %Stack{},
            parent_type_stack: %Stack{},
            input_type_stack: %Stack{},
            field_def_stack: %Stack{},
            directive: nil,
            argument: nil

  @doc """
  Return the top of the type stack, or nil if empty.
  """
  def type(type_info), do: Stack.peek(type_info.type_stack)

  @doc """
  Dereferences a type to a proper type. If the type is a List or NonNull it is dereferenced,
  otherwise it just returns its type argument.
  """
  def named_type(%List{} = type), do: named_type(type.ofType)
  def named_type(%NonNull{} = type), do: named_type(type.ofType)
  def named_type(type), do: type

  @doc """
  Return the top of the parent type stack, or nil if empty.
  """
  def parent_type(type_info) do
    Stack.peek(type_info.parent_type_stack)
  end

  @doc """
  Return the top of the input type stack, or nil if empty.
  """
  def input_type(type_info) do
    Stack.peek(type_info.input_type_stack)
  end

  @doc """
  Return the top of the field def stack, or nil if empty.
  """
  def field_def(type_info) do
    Stack.peek(type_info.field_def_stack)
  end

  @doc """
  Return the current directive
  """
  def directive(type_info) do
    type_info.directive
  end

  def find_field_def(schema, parent_type, field_node) do
    cond do
      field_node.name.value == Introspection.meta(:schema)[:name] && schema.query == parent_type ->
        Introspection.meta(:schema)
      field_node.name.value == Introspection.meta(:type)[:name] && schema.query == parent_type ->
        Introspection.meta(:type)
      field_node.name.value == Introspection.meta(:typename)[:name] ->
        Introspection.meta(:typename)
      true ->
        find_field_def(parent_type, field_node)
    end
  end

  defp find_field_def(%Interface{} = parent_type, field_node) do
    CompositeType.get_field(parent_type, field_node.name.value)
  end
  defp find_field_def(%ObjectType{} = parent_type, field_node) do
    CompositeType.get_field(parent_type, field_node.name.value)
  end
  defp find_field_def(_, _), do: nil
end
