ViteRuby.configure do |config|
    config.js_importmap_paths = ['vite', 'vite-dev']
    config.public_output_dir = Rails.root.join('public/vite')
  end