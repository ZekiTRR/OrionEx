import { addCollection, _api } from 'iconify-icon';
import icons from './generated-icons.json';
// Keep icon resolution strictly offline: an empty resource list disables the
// public Iconify API fallback, so only the bundled subset can ever render.
_api.setFetch(undefined);
for (const collection of icons) addCollection(collection);
