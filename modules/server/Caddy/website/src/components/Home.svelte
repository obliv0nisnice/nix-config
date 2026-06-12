<script>
    import {user} from "../stores/auth.js";
    import VideoBackground from "./VideoBackground.svelte";
    import { navigate } from 'svelte-routing';
    function goToUserManagement() {
        navigate('/user-management');
    }

    window.onload = async function() {
        
        const isLoggedIn = await verifyToken();
        if (isLoggedIn) {
            navigate("/home");
        } else {
            navigate("/");
        }
    };




</script>

<main>
<VideoBackground>
    <div class="container-fluid d-flex align-items-center justify-content-center" style="height: 98vh;">

        
        <pre>
        ██░ ██ ▓█████  ██▓     ██▓     ▒█████     ▄▄▄█████▓ ██░ ██ ▓█████  ██▀███  ▓█████ 
        ▓██░ ██▒▓█   ▀ ▓██▒    ▓██▒    ▒██▒  ██▒   ▓  ██▒ ▓▒▓██░ ██▒▓█   ▀ ▓██ ▒ ██▒▓█   ▀ 
        ▒██▀▀██░▒███   ▒██░    ▒██░    ▒██░  ██▒   ▒ ▓██░ ▒░▒██▀▀██░▒███   ▓██ ░▄█ ▒▒███   
        ░▓█ ░██ ▒▓█  ▄ ▒██░    ▒██░    ▒██   ██░   ░ ▓██▓ ░ ░▓█ ░██ ▒▓█  ▄ ▒██▀▀█▄  ▒▓█  ▄ 
        ░▓█▒░██▓░▒████▒░██████▒░██████▒░ ████▓▒░     ▒██▒ ░ ░▓█▒░██▓░▒████▒░██▓ ▒██▒░▒████▒
        ▒ ░░▒░▒░░ ▒░ ░░ ▒░▓  ░░ ▒░▓  ░░ ▒░▒░▒░      ▒ ░░    ▒ ░░▒░▒░░ ▒░ ░░ ▒▓ ░▒▓░░░ ▒░ ░
        ▒ ░▒░ ░ ░ ░  ░░ ░ ▒  ░░ ░ ▒  ░  ░ ▒ ▒░        ░     ▒ ░▒░ ░ ░ ░  ░  ░▒ ░ ▒░ ░ ░  ░
        ░  ░░ ░   ░     ░ ░     ░ ░   ░ ░ ░ ▒       ░       ░  ░░ ░   ░     ░░   ░    ░   
        ░  ░  ░   ░  ░    ░  ░    ░  ░    ░ ░               ░  ░  ░   ░  ░   ░        ░  ░
                                <h1>Willkommen, {$user.username}!</h1>
        <div class="btn-group position-absolute top-60 start-50 translate-middle">
            <button type="button" class="btn custom-btn" on:click={goToUserManagement}>User Management</button>
            <button type="button" class="btn custom-btn">Stash</button>
            <button type="button" class="btn custom-btn">Cloud</button>
        </div>
            
            
        </pre>
        
    </div>
</VideoBackground>
</main>
<style>
    pre {
        color: goldenrod;
    }
    
</style>
