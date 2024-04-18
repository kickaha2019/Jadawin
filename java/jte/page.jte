@import com.alofmethbin.jadawin.Article
@param Article article

<!DOCTYPE html>
<HTML LANG="en"><HEAD><TITLE>${ article.getBlurb() }</TITLE>
<meta name="description" content="${ article.getBlurb() }">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta http-equiv="Content-Type" content="text/html;charset=utf-8" >
@if( article.hasOverlay() )
<script>
function showOverlay(image_path) {
  var img = '<IMG SRC="' + image_path + '" onclick="hideOverlay()">';
  document.getElementById("overlay").style.display = 'flex';
  document.getElementById("overlay_image").innerHTML = img;
}
function hideOverlay() {
  document.getElementById("overlay").style.display = 'none';
}
</script>
@endif
<style>
@template.css( article)
</style>
@template.breadcrumbs_origin_head( article)
</HEAD><BODY>
@if( article.hasOverlay() )
<DIV ID="overlay" CLASS="overlay" onclick="hideOverlay()">
  <DIV CLASS="overlay_back size1 size2 size3" onclick="hideOverlay()"></DIV>
  <DIV CLASS="size1 size2 size3" ID="overlay_image" onclick="hideOverlay()"></DIV>
  <DIV CLASS="overlay_front size1 size2 size3" onclick="hideOverlay()"></DIV>
</DIV>
@endif
<DIV CLASS="page">
<DIV CLASS="legend">Jadawin - a simple static site generator</DIV>
@template.breadcrumbs_origin_head( article)
<DIV CLASS="payload content ${ article.getIndexStyle() }">
  @if( article.hasContent() )
    <DIV CLASS="story t1">
      @template.title( article)
      @template.story_indexes( article)
      @template.content( article)
      @if(article.getLineCount() > 20)
        @template.navigation( article)
      @endif
    </DIV>
  @endif
  @template.text_indexes( article)
  @template.image_indexes( article)
  @template.rect_indexes( article)
</DIV>
</DIV></BODY></HTML>
