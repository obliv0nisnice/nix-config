<script>
    import VideoBackground from "./VideoBackground.svelte";

    let username = '';
    let password = '';
    let uploadResponse = '';
    const handleAddUser = async () => {
        console.log("Adding user with username:", username);

        const response = await fetch('https://nestler.duckdns.org/api/user', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username, password }),
        });

        console.log("Received response:", response);

        if (response.ok) {
            const responseData = await response.json();
            uploadResponse = `User added successfully: ${responseData.Message}`;
        } else {
            const errorData = await response.json();
            uploadResponse = `Failed to add user: ${errorData.Message}`;
        }
    };

</script>

<VideoBackground>
    <main class="container mt-5">
        <h1>Add User</h1>
        <form on:submit|preventDefault={handleAddUser}>
            <div class="mb-3">
                <label for="new-username" class="form-label">New Username</label>
                <input type="text" class="form-control" id="new-username" bind:value={username} required>
            </div>
            <div class="mb-3">
                <label for="new-password" class="form-label">New Password</label>
                <input type="password" class="form-control" id="new-password" bind:value={password} required>
            </div>
            <button type="submit" class="btn btn-primary">Add User</button>
        </form>
        {#if uploadResponse}
            <div class="mt-3 alert alert-info">{uploadResponse}</div>
        {/if}
    </main>
</VideoBackground>