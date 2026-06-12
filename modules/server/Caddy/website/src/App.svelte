<script>
    import { onMount } from 'svelte';
    import { Router, Route, navigate } from 'svelte-routing';
    import Login from "./components/Login.svelte";
    import Home from "./components/Home.svelte";
    import UserManagement from "./components/UserManagement.svelte";
    import { user, verifyToken } from './stores/auth';
    
    onMount(async () => {
        const isLoggedIn = await verifyToken();
        if (isLoggedIn) {
            navigate('/home');
        } else {
            navigate('/');
        }
    });
    
    user.subscribe(value => {
        if (!value.username) {
            navigate('/');
        }
    });
</script>

<main>
    <Router>
        <Route path="/" component={Login} />
        <Route path="/home" component={Home} />
        <Route path="/user-management" component={UserManagement} />
    </Router>
</main>
