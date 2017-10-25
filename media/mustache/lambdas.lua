g = 0
return {
   tests={
      {
         desc='A lambda\'s return value should be interpolated.',
         data={
            lambda=function() return "world" end,
         },
         template='Hello, {{lambda}}!',
         expected='Hello, world!',
         name='Interpolation'
      },
      {
         desc='A lambda\'s return value should be parsed.',
         data={
            planet='world',
            lambda=function() return "{{planet}}" end,
         },
         template='Hello, {{lambda}}!',
         expected='Hello, world!',
         name='Interpolation - Expansion'
      },
      {
         desc='A lambda\'s return value should parse with the default delimiters.',
         data={
            planet='world',
            lambda=function() return "|planet| => {{planet}}" end,
         },
         template='{{= | | =}}\nHello, (|&lambda|)!',
         expected='Hello, (|planet| => world)!',
         name='Interpolation - Alternate Delimiters'
      },
      {
         desc='Interpolated lambdas should not be cached.',
         data={
            lambda=function() g = g + 1; return g; end,
         },
         template='{{lambda}} == {{{lambda}}} == {{lambda}}',
         expected='1 == 2 == 3',
         name='Interpolation - Multiple Calls'
      },
      {
         desc='Lambda results should be appropriately escaped.',
         data={
            lambda=function() return ">" end,
         },
         template='<{{lambda}}{{{lambda}}}',
         expected='<&gt;>',
         name='Escaping'
      },
      {
         desc='Lambdas used for sections should receive the raw section string.',
         data={
            lambda=function(txt) return txt == "{{x}}" and "yes" or "no" end,
            x='Error!'
         },
         template='<{{#lambda}}{{x}}{{/lambda}}>',
         expected='<yes>',
         name='Section'
      },
      {
         desc='Lambdas used for sections should have their results parsed.',
         data={
            planet='Earth',
            lambda=function(txt) return txt .. "{{planet}}" .. txt end,
         },
         template='<{{#lambda}}-{{/lambda}}>',
         expected='<-Earth->',
         name='Section - Expansion'
      },
      {
         desc='Lambdas used for sections should parse with the current delimiters.',
         data={
            planet='Earth',
            lambda=function(txt) return txt .. "{{planet}} => |planet|" .. txt end,
         },
         template='{{= | | =}}<|#lambda|-|/lambda|>',
         expected='<-{{planet}} => Earth->',
         name='Section - Alternate Delimiters'
      },
      {
         desc='Lambdas used for sections should not be cached.',
         data={
            lambda=function(txt) return "__" .. txt .. "__" end,
         },
         template='{{#lambda}}FILE{{/lambda}} != {{#lambda}}LINE{{/lambda}}',
         expected='__FILE__ != __LINE__',
         name='Section - Multiple Calls'
      },
      {
         desc='Lambdas used for inverted sections should be considered truthy.',
         data={
            lambda=function(txt) return false end,
            static='static',
         },
         template='<{{^lambda}}{{static}}{{/lambda}}>',
         expected='<>',
         name='Inverted Section'
      }
   },
}
