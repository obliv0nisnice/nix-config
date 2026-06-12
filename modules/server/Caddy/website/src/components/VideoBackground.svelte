<script>
    export let src = "/img/LiveWallpaper.mp4"; 
</script>

<div class="video-container">
    <video muted autoplay loop>
        <source {src} type="video/webm" />
    </video>
    <slot></slot>
</div>

<style>
    .video-container {
        height: 100%;
        width: 100%;
        position: relative;
    }

    .video-container video {
        width: 100%;
        height: 100%;
        position: absolute;
        object-fit: cover;
        z-index: -1;
    }
    
</style>
