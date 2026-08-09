local tl = require("teal.api.v2")

local function check(code)
   local result = tl.check_string(code)
   assert.same({}, result.syntax_errors)
   assert.same({}, result.type_errors)
   return result.ast
end

describe("declaration type metadata", function()
   it("stores stable variable declaration bindings", function()
      local ast = check([[
         local inferred = 1
         local widened: number = 1
         global initialized = "hello"
      ]])

      assert.same("integer", ast[1].vars[1].declaration_type.typename)
      assert.same("number", ast[2].vars[1].declaration_type.typename)
      assert.same("string", ast[3].vars[1].declaration_type.typename)
   end)

   it("does not annotate an untyped forward global", function()
      local result = tl.check_string("global forward")
      assert.same({}, result.syntax_errors)
      assert.same("variable 'forward' has no type or initial value", result.type_errors[1].msg)
      assert.is_nil(result.ast[1].vars[1].declaration_type)
   end)

   it("stores local and global function contracts", function()
      local ast = check([[
         local function local_fn(x: number): string
            return tostring(x)
         end
         global function global_fn(x: string): boolean
            return x == "yes"
         end
      ]])

      local local_type = ast[1].declaration_type
      assert.same("function", local_type.typename)
      assert.same("number", local_type.args.tuple[1].typename)
      assert.same("string", local_type.rets.tuple[1].typename)

      local global_type = ast[2].declaration_type
      assert.same("function", global_type.typename)
      assert.same("string", global_type.args.tuple[1].typename)
      assert.same("boolean", global_type.rets.tuple[1].typename)
   end)

   it("stores record method and type declaration contracts", function()
      local ast = check([[
         local record Item
            value: number
            get: function(self: Item): number
         end
         function Item:get(): number
            return self.value
         end
         local type Alias = string
      ]])

      local method_type = ast[2].declaration_type
      assert.same("function", method_type.typename)
      assert.same("number", method_type.rets.tuple[1].typename)

      local type_binding = ast[3].var.declaration_type
      assert.same("typedecl", type_binding.typename)
      assert.same("string", type_binding.def.typename)
   end)
end)
