import { writable } from 'svelte/store';

export const user = writable({ username: null });
export const isloggedin =writable(false);

export async function login(username, password) {
    const response = await fetch('https://nestler.duckdns.org/api/login/userlogin', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ username, password }),
        credentials: 'include' 
    });

    const data = await response.json();

    if (response.ok) {
        user.set({ username });
        isloggedin.set(true);
    } else {
        throw new Error(data.Message || 'Login failed');
        
    }
}

export async function verifyToken() {
    const response = await fetch('https://nestler.duckdns.org/api/login/verifyToken', {
        method: 'GET',
        credentials: 'include'
    });

    const data = await response.json();

    if (response.ok) {
        user.set({ username: data.Username });
        isloggedin.set(true);
    } else {
        user.set({ username: null });
    }
}