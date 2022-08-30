import { writable } from 'svelte/store';

const loaderFunction = () => {
	const { subscribe, update, set } = writable({
		status: 'IDLE' // IDLE, LOADING, NAVIGATING
		// message: ''
	});

	function setNavigate(isNavigating: boolean) {
		update(() => {
			return {
				status: isNavigating ? 'NAVIGATING' : 'IDLE'
				// message: ''
			};
		});
	}

	return { subscribe, update, set, setNavigate };
};

export const loading = loaderFunction();
