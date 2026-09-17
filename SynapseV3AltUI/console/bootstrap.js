import { hydrate, reportError } from '../src/bridge';
import '../src/localIcons';
hydrate().then(() => import('./console.js')).catch(reportError);
