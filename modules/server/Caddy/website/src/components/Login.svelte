<script>
    import { login } from '../stores/auth';
    import VideoBackground from "./VideoBackground.svelte";
    import { navigate } from 'svelte-routing';
    import * as search from 'jquery';


    let username = '';
    let password = '';
    let loginResponse;

    async function handleLogin() {
        loginResponse = ''; 
        try {
            await login(username, password);
            search('#login').modal('toggle');
            navigate('/home');
        } catch (error) {
            loginResponse = error.message;
        }
    }
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
            <div class="btn-group position-absolute top-60 start-50 translate-middle">
                <button type="button" class="btn custom-btn" data-bs-toggle="modal" data-bs-target="#login">Login</button>
            </div>
            </pre>

            <!-- The Modal -->
            <div class="modal" id="login">
                <div class="modal-dialog ">
                    <div class="modal-content">

                        <!-- Modal Header -->
                        <div class="modal-header">
                            <h4 class="modal-title">Login</h4>
                            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                        </div>

                        <!-- Modal body -->
                        <div class="modal-body">
                            <h1>Login</h1>
                            <form on:submit|preventDefault={handleLogin}>
                                <div class="mb-3">
                                    <label for="username" class="form-label">Username</label>
                                    <input type="text" class="form-control" id="username" bind:value={username} required>
                                </div>
                                <div class="mb-3">
                                    <label for="password" class="form-label">Password</label>
                                    <input type="password" class="form-control" id="password" bind:value={password} required>
                                </div>
                                <button type="submit" class="btn btn-secondary">Login</button>
                            </form>
                            {#if loginResponse}
                                <div class="mt-3 alert alert-info">{loginResponse}</div>
                            {/if}
                        </div>

                        <!-- Modal footer -->
                        <div class="modal-footer">
                            <button type="button" class="btn btn-danger" data-bs-dismiss="modal">Close</button>
                        </div>

                    </div>
                </div>
            </div>
        </div>
    </VideoBackground>
</main>

<style>
    pre {
        color: goldenrod;
    }
    .custom-btn {
        color: lightgray;
    }
</style>
