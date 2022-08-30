import { asyncTimeout } from "$lib/timeout";
import { PUBLIC_strapiURL } from "$env/static/public";

// export async function load() {
// 	await asyncTimeout(1000);
// 	const response = await fetch(`${PUBLIC_strapiURL}/api/neuigkeiten?populate=*`);
// 	const receivedData = await response.json();
// 	// the 'data' property is going to be accesible in the corresponding +page.svelte
// 	return {
// 		data: receivedData.data
// 	};
// }
