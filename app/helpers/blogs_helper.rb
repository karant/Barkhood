module BlogsHelper
  def blog_tab_path(blog)
    dog_path(blog.dog, :anchor => "tBlog")
  end

  def blog_tab_url(blog)
    dog_url(blog.dog, :anchor => "tBlog")
  end  
end
