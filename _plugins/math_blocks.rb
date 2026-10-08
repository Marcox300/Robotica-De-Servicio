Jekyll::Hooks.register :pages, :pre_render do |page|
  page.content = page.content.gsub(
    /```math\s*\n(.*?)```/m,
    '<div class="math-block">\\[\\1\\]</div>'
  )

  page.content = page.content.gsub(
    'PRUEBA_MATH',
    '<div style="color:red;">PLUGIN FUNCIONANDO</div>'
  )
end
